//
//  WindowFixer.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/9.
//

import Cocoa

// MARK: - WindowFixer

/// Monitors window creation events for a specific application using Accessibility API.
final class WindowFixer {
  // MARK: - Types

  typealias WindowChangeHandler = (
    _ newWindows: [AXUIElement],
    _ allWindows: [AXUIElement],
    _ previousWindows: [AXUIElement]
  ) -> Void

  // MARK: - Properties

  let appBundleIdentifier: String
  private let onWindowChanged: WindowChangeHandler

  private var axObserver: AXObserver?
  private var axApplication: AXUIElement?
  private var trackedWindows: [AXUIElement] = []

  // MARK: - Initialization

  init(appBundleIdentifier: String, onWindowChanged: @escaping WindowChangeHandler) {
    self.appBundleIdentifier = appBundleIdentifier
    self.onWindowChanged = onWindowChanged

    setUp()
  }

  deinit {
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    detachObserver()
  }
}

// MARK: - Setup

private extension WindowFixer {
  func setUp() {
    startMonitoringAppLaunch()
    attachToRunningAppIfNeeded()
  }
}

// MARK: - Application Monitoring

private extension WindowFixer {
  func startMonitoringAppLaunch() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(handleAppWillLaunch(_:)),
      name: NSWorkspace.willLaunchApplicationNotification,
      object: nil
    )
  }

  @objc func handleAppWillLaunch(_ notification: Notification) {
    guard let app = notification.runningApplication,
          app.bundleIdentifier == appBundleIdentifier
    else {
      return
    }
    attachObserver(to: app)
  }

  func attachToRunningAppIfNeeded() {
    guard let app = findRunningApp() else { return }
    attachObserver(to: app)
  }

  func findRunningApp() -> NSRunningApplication? {
    NSRunningApplication
      .runningApplications(withBundleIdentifier: appBundleIdentifier)
      .first
  }
}

// MARK: - AXObserver Management

private extension WindowFixer {
  func attachObserver(to app: NSRunningApplication) {
    detachObserver()

    let pid = app.processIdentifier
    axApplication = AXUIElementCreateApplication(pid)

    guard let observer = createObserver(for: pid),
          registerWindowNotification(observer)
    else {
      return
    }

    axObserver = observer
    addToRunLoop(observer)
    trackedWindows = fetchWindows()
  }

  func detachObserver() {
    guard let observer = axObserver, let app = axApplication else { return }

    removeFromRunLoop(observer)
    AXObserverRemoveNotification(observer, app, kAXWindowCreatedNotification as CFString)

    axObserver = nil
    axApplication = nil
    trackedWindows = []
  }

  func createObserver(for pid: pid_t) -> AXObserver? {
    var observer: AXObserver?
    let callback: AXObserverCallback = { _, _, _, refcon in
      guard let refcon else { return }
      let instance = Unmanaged<WindowFixer>.fromOpaque(refcon).takeUnretainedValue()
      instance.handleWindowCreated()
    }

    let error = AXObserverCreate(pid, callback, &observer)
    guard error == .success else { return nil }

    return observer
  }

  func registerWindowNotification(_ observer: AXObserver) -> Bool {
    guard let app = axApplication else { return false }

    let pointer = Unmanaged.passUnretained(self).toOpaque()
    let error = AXObserverAddNotification(
      observer,
      app,
      kAXWindowCreatedNotification as CFString,
      pointer
    )

    return error == .success
  }

  func addToRunLoop(_ observer: AXObserver) {
    let runLoopSource = AXObserverGetRunLoopSource(observer)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
  }

  func removeFromRunLoop(_ observer: AXObserver) {
    let runLoopSource = AXObserverGetRunLoopSource(observer)
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
  }
}

// MARK: - Window Tracking

private extension WindowFixer {
  func handleWindowCreated() {
    let currentWindows = fetchWindows()
    let newWindows = currentWindows.filter { !trackedWindows.contains($0) }

    guard !newWindows.isEmpty else { return }

    onWindowChanged(newWindows, currentWindows, trackedWindows)
    trackedWindows = currentWindows
  }

  func fetchWindows() -> [AXUIElement] {
    guard let app = axApplication else { return [] }
    return app.axWindows ?? []
  }
}

// MARK: - Notification Helpers

private extension Notification {
  var runningApplication: NSRunningApplication? {
    userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
  }
}
