//
//  FinderWindowFixer.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa

// MARK: - FinderWindowFixer

enum FinderWindowFixer {
  private static var instance: WindowFixer?

  /// Must be called on the main thread.
  @discardableResult
  static func shared() -> WindowFixer {
    if let instance {
      return instance
    }

    let fixer = WindowFixer(appBundleIdentifier: .finderBundleIdentifier) { newWindows, _, previousWindows in
      handleNewWindows(newWindows, previousWindows: previousWindows)
    }
    instance = fixer
    return fixer
  }

  /// Process existing Finder windows (call after delayed initialization due to permission grant)
  static func processExistingWindows() {
    guard let finderApp = NSRunningApplication
      .runningApplications(withBundleIdentifier: .finderBundleIdentifier)
      .first
    else { return }

    let axApp = AXUIElementCreateApplication(finderApp.processIdentifier)
    guard let windows = axApp.axWindows else { return }

    handleNewWindows(windows, previousWindows: [])
  }
}

// MARK: - Window Event Handling

private extension FinderWindowFixer {
  static func handleNewWindows(_ newWindows: [AXUIElement], previousWindows: [AXUIElement]) {
    let shouldChangePosition = !AppState.shared.effectFirstWindow || hasNoValidWindow(previousWindows)
    let resizableWindows = newWindows.filter(\.shouldResize)

    for window in resizableWindows {
      applyWindowSettings(to: window, changePosition: shouldChangePosition)
    }
  }

  static func applyWindowSettings(to window: AXUIElement, changePosition: Bool) {
    guard let targetFrame = calculateTargetFrame(for: window, changePosition: changePosition) else {
      return
    }

    animateWindow(window, to: targetFrame)
  }
}

// MARK: - Frame Calculation

private extension FinderWindowFixer {
  static func calculateTargetFrame(for window: AXUIElement, changePosition: Bool) -> CGRect? {
    let state = AppState.shared
    let shouldChangePosition = changePosition && state.placeWindow
    let shouldResize = state.resizeWindow

    // Nothing to do if neither positioning nor resizing is enabled
    guard shouldChangePosition || shouldResize else {
      return nil
    }

    // Determine target size
    let targetSize: CGSize
    if shouldResize {
      targetSize = state.windowSize
    } else if let currentSize = window.getSize() {
      targetSize = currentSize
    } else {
      return nil
    }

    // Determine target position
    let targetPosition: CGPoint
    if shouldChangePosition, let position = calculateWindowPosition(for: targetSize) {
      targetPosition = position
    } else if let currentPosition = window.getPosition() {
      targetPosition = currentPosition
    } else {
      return nil
    }

    return CGRect(origin: targetPosition, size: targetSize)
  }

  static func calculateWindowPosition(for windowSize: CGSize) -> CGPoint? {
    let targetScreen = resolveTargetScreen()
    let mainScreen = NSScreen.screens.first

    guard let targetScreen, let mainScreen else { return nil }

    let visibleFrame = targetScreen.visibleFrame.toAccessibilityCoordinates(relativeTo: mainScreen.frame)

    return calculatePositionInFrame(visibleFrame, windowSize: windowSize)
  }

  static func resolveTargetScreen() -> NSScreen? {
    switch AppState.shared.screen {
    case .main:
      NSScreen.screens.first
    case .current:
      NSScreen.main
    }
  }

  static func calculatePositionInFrame(_ frame: CGRect, windowSize: CGSize) -> CGPoint {
    switch AppState.shared.place {
    case .center:
      frame.centerPoint(for: windowSize)
    case .custom:
      frame.originPoint(withOffset: AppState.shared.position)
    }
  }
}

// MARK: - Window Animation

private extension FinderWindowFixer {
  static func animateWindow(_ window: AXUIElement, to targetFrame: CGRect) {
    // Check if animation is disabled
    guard AppState.shared.enableAnimation else {
      window.setPosition(targetFrame.origin)
      window.setSize(targetFrame.size)
      return
    }

    guard let currentPosition = window.getPosition(),
          let currentSize = window.getSize()
    else {
      // Fallback: set directly without animation
      window.setPosition(targetFrame.origin)
      window.setSize(targetFrame.size)
      return
    }

    let startFrame = CGRect(origin: currentPosition, size: currentSize)
    let animator = WindowAnimator(
      window: window,
      from: startFrame,
      to: targetFrame,
      duration: AppState.shared.animationDuration
    )
    animator.start()
  }
}

// MARK: - Window Validation

private extension FinderWindowFixer {
  static func hasNoValidWindow(_ windows: [AXUIElement]) -> Bool {
    guard !windows.isEmpty else { return true }

    // Only count actual windows (AXWindow role), not other UI elements
    // like AXScrollArea (desktop view) that Finder reports on macOS 26+
    return windows.allSatisfy { $0.axRole != kAXWindowRole }
  }
}

// MARK: - Constants

private extension String {
  static let finderBundleIdentifier = "com.apple.finder"
}
