//
//  AppDelegate.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/5.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_: Notification) {
    populateMainMenu()
  }

  func applicationDidFinishLaunching(_: Notification) {
    AXUtils.checkIsTrusted()

    // Initialize update checker and check on launch if configured
    UpdateChecker.shared.checkOnLaunchIfNeeded()

    MenuBarItemController.shared.setUp()

    FinderWindowFixer.shared()
  }

  func applicationDidBecomeActive(_: Notification) {
    AXUtils.checkTrustStatus()
  }
}

extension AppDelegate {
  func populateMainMenu() {
    let mainMenu = NSMenu(title: "Main Menu")
    let fileMenuItem = mainMenu.addItem(withTitle: "File", action: nil, keyEquivalent: "")
    let submenu = NSMenu(title: String(localized: "File"))

    let closeWindowItem = NSMenuItem(title: String(localized: "Close Window"),
                                     action: #selector(NSWindow.performClose(_:)),
                                     keyEquivalent: "w")
    submenu.addItem(closeWindowItem)

    mainMenu.setSubmenu(submenu, for: fileMenuItem)

    NSApp.mainMenu = mainMenu
  }
}
