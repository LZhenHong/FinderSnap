//
//  AppDelegate.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/5.
//

import Cocoa
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
  private var permissionCancellable: AnyCancellable?

  func applicationWillFinishLaunching(_: Notification) {
    populateMainMenu()
  }

  func applicationDidFinishLaunching(_: Notification) {
    // Initialize update checker and check on launch if configured
    UpdateChecker.shared.checkOnLaunchIfNeeded()

    MenuBarItemController.shared.setUp()

    if !AppState.shared.onboardingCompleted {
      showOnboarding()
    } else {
      AXUtils.checkIsTrusted()
      initializeWindowFixerWhenAuthorized()
    }
  }

  func applicationDidBecomeActive(_: Notification) {
    AXUtils.checkTrustStatus()
  }
}

// MARK: - Onboarding

private extension AppDelegate {
  func showOnboarding() {
    let settingsWindowController = MenuBarItemController.shared.settingsWindowController
    OnboardingWindowController.showIfNeeded(settingsWindowController: settingsWindowController)
  }
}

// MARK: - Window Fixer Setup

private extension AppDelegate {
  func initializeWindowFixerWhenAuthorized() {
    // If already authorized, initialize immediately
    if AXUtils.trusted {
      FinderWindowFixer.shared()
      return
    }

    // Listen for Finder activation to trigger permission check
    // This handles the case where user grants permission then opens Finder directly
    var finderObserver: NSObjectProtocol?
    finderObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { notification in
      guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            app.bundleIdentifier == "com.apple.finder"
      else { return }
      AXUtils.checkTrustStatus()
    }

    // When permission is granted, remove Finder observer and initialize WindowFixer
    permissionCancellable = AXUtils.trustPublisher
      .first(where: { $0 })
      .sink { [weak self] _ in
        self?.permissionCancellable = nil
        if let observer = finderObserver {
          NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        FinderWindowFixer.shared()
        // Process any existing windows that were opened before initialization
        FinderWindowFixer.processExistingWindows()
      }
  }
}

// MARK: - Menu Setup

extension AppDelegate {
  func populateMainMenu() {
    let mainMenu = NSMenu(title: "Main Menu")
    let fileMenuItem = mainMenu.addItem(withTitle: "File", action: nil, keyEquivalent: "")
    let submenu = NSMenu(title: String(localized: "File"))

    let closeWindowItem = NSMenuItem(
      title: String(localized: "Close Window"),
      action: #selector(NSWindow.performClose(_:)),
      keyEquivalent: "w"
    )
    submenu.addItem(closeWindowItem)

    mainMenu.setSubmenu(submenu, for: fileMenuItem)

    NSApp.mainMenu = mainMenu
  }
}
