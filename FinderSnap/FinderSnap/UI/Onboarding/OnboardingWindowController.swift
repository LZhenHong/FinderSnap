//
//  OnboardingWindowController.swift
//  FinderSnap
//
//  Created by Eden on 2026/4/24.
//

import Cocoa
import SettingsKit
import SwiftUI

/// Manages the onboarding window displayed on first launch.
/// Presents a centered, non-resizable window that guides users through
/// welcome, accessibility permission, and quick setup steps.
final class OnboardingWindowController: NSWindowController {
  private let settingsWindowController: SettingsWindowController

  /// Strong reference to keep the controller alive while the window is shown.
  /// NSWindow.delegate is a weak reference, so without this the controller
  /// would be deallocated immediately after `showIfNeeded` returns.
  private static var currentController: OnboardingWindowController?

  init(settingsWindowController: SettingsWindowController) {
    self.settingsWindowController = settingsWindowController

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = String(localized: "Welcome")
    window.titlebarAppearsTransparent = true
    window.center()
    window.isReleasedWhenClosed = false
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true

    super.init(window: window)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowWillClose(_:)),
      name: NSWindow.willCloseNotification,
      object: window
    )

    window.contentView = NSHostingView(
      rootView: OnboardingView(
        state: .shared,
        onComplete: { [weak self] in
          self?.dismiss()
        },
        onOpenSettings: { [weak self] in
          self?.dismiss()
          self?.settingsWindowController.show()
        }
      )
    )
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Shows the onboarding window if the user hasn't completed onboarding yet.
  static func showIfNeeded(settingsWindowController: SettingsWindowController) {
    guard !AppState.shared.onboardingCompleted else { return }
    let controller = OnboardingWindowController(settingsWindowController: settingsWindowController)
    currentController = controller
    controller.showWindow(nil)
  }

  /// Closes the onboarding window and releases the strong reference.
  private func dismiss() {
    close()
    Self.currentController = nil
  }

  @objc
  private func windowWillClose(_ notification: Notification) {
    guard notification.object as? NSWindow === window else { return }
    // Mark onboarding as completed when the user closes the window
    // via the close button, even if they didn't finish all steps.
    AppState.shared.onboardingCompleted = true
    Self.currentController = nil
  }
}
