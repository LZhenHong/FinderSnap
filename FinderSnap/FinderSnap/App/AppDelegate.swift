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
    migrateOnboardingStateForExistingUsers()
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
    }

    // Always initialize window fixer — it handles both immediate setup
    // (when already authorized) and deferred setup via permission publisher.
    initializeWindowFixerWhenAuthorized()
  }

  func applicationDidBecomeActive(_: Notification) {
    AXUtils.checkTrustStatus()
  }
}

// MARK: - Onboarding

private extension AppDelegate {
  /// Migration for existing users upgrading from versions before onboarding.
  /// If `onboardingCompleted` key does not exist but other FinderSnap-specific
  /// keys do, this is an existing install — skip onboarding.
  func migrateOnboardingStateForExistingUsers() {
    guard UserDefaults.standard.object(forKey: "onboardingCompleted") == nil else { return }

    // Check for keys that are explicitly written by code paths (not macro defaults),
    // making this safe regardless of whether @storage eagerly writes defaults.
    let isExistingUser = UserDefaults.standard.object(forKey: "lastCheckTimestamp") != nil
      || UserDefaults.standard.object(forKey: "dismissedVersion") != nil

    if isExistingUser {
      UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
  }

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
