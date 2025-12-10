//
//  MenuBarItemController.swift
//  FinderSnap
//
//  Created by Eden on 2023/9/20.
//

import Cocoa
import SettingsKit

final class MenuBarItemController {
  static let shared = MenuBarItemController()

  private var statusItem: NSStatusItem!

  private lazy var settingsWindowController = SettingsWindowController(
    panes: [GeneralSettingPane(), UpdateSettingPane(), AboutSettingPane()],
    title: String(localized: "Settings")
  )

  private init() {}

  func setUp() {
    statusItem = setUpStatusItem()
  }

  private func setUpStatusItem() -> NSStatusItem? {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    guard let btn = statusItem.button else {
      return nil
    }

    statusItem.isVisible = true
    statusItem.behavior = .terminationOnRemoval

    btn.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "FinderSnap")
    btn.image?.size = NSSize(width: 18, height: 18)
    btn.image?.isTemplate = true

    btn.target = self
    btn.action = #selector(onStatusBarItemHandle(_:))
    btn.sendAction(on: [.leftMouseUp, .rightMouseUp])

    return statusItem
  }

  @objc private func onStatusBarItemHandle(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }

    switch event.type {
    case .leftMouseUp:
      showMenu(sender)
    case .rightMouseUp:
      break
    default:
      break
    }
  }

  private func showMenu(_: NSStatusBarButton) {
    let menu = setUpMenu()
    showMenu(menu, for: statusItem)
  }

  private func showMenu(_ menu: NSMenu, for item: NSStatusItem) {
    item.menu = menu
    /// Programmatically trigger the menu display. Setting menu to nil afterward
    /// allows us to intercept clicks again via sendAction(on:) instead of
    /// always showing the menu automatically.
    item.button?.performClick(nil)
    item.menu = nil
  }

  private func setUpMenu() -> NSMenu {
    let menu = createMenu()
    // https://github.com/onmyway133/blog/issues/428
    menu.autoenablesItems = false
    return menu
  }

  private func createMenu() -> NSMenu {
    NSMenu {
      // Update available notification
      if let version = UpdateChecker.shared.updateVersionPublisher.value {
        MenuItemBuilder()
          .title(String(localized: "Update Available (\(version))"))
          .onSelect {
            self.settingsWindowController.show(paneIndex: 1)
          }
        NSMenuItem.separator()
      }

      if !AXUtils.trusted {
        MenuItemBuilder()
          .title(String(localized: "Open Accessibility Settings"))
          .onSelect {
            AXUtils.openAccessibilitySetting()
          }
        NSMenuItem.separator()
      }
      MenuItemBuilder()
        .title(String(localized: "Launch at Login"))
        .onHighlight(LaunchAtLogin.enabledPublisher.eraseToAnyPublisher())
        .onSelect {
          LaunchAtLogin.toggle()
        }
      MenuItemBuilder()
        .title(String(localized: "Settings"))
        .keyEquivalent(",")
        .onSelect {
          self.settingsWindowController.show()
        }
      NSMenuItem.separator()
      MenuItemBuilder()
        .title(String(localized: "Quit"))
        .onSelect {
          NSApp.terminate(self)
        }
    }
  }
}
