//
//  MenuItemBuilder.swift
//  FinderSnap
//
//  Created by Eden on 2023/9/28.
//

import AppKit
import Combine

// MARK: - MenuItemBuilder

final class MenuItemBuilder {
  private let menuItem = NSMenuItem()
  private var subscriptions = Set<AnyCancellable>()
  private var selectHandler: (() -> Void)?

  // MARK: - Title

  @discardableResult
  func title(_ title: LocalizedStringResource) -> Self {
    self.title(String(localized: title))
  }

  @discardableResult
  func title(_ title: String) -> Self {
    menuItem.title = title
    return self
  }

  // MARK: - Action

  @discardableResult
  func onSelect(_ handler: @escaping () -> Void) -> Self {
    selectHandler = handler
    return self
  }

  // MARK: - State Binding

  @discardableResult
  func onEnable(_ publisher: AnyPublisher<Bool, Never>) -> Self {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak menuItem] isEnabled in
        menuItem?.isEnabled = isEnabled
      }
      .store(in: &subscriptions)
    return self
  }

  @discardableResult
  func onHighlight(_ publisher: AnyPublisher<Bool, Never>) -> Self {
    publisher
      .receive(on: DispatchQueue.main)
      .sink { [weak menuItem] isHighlighted in
        menuItem?.state = isHighlighted ? .on : .off
      }
      .store(in: &subscriptions)
    return self
  }

  // MARK: - Configuration

  @discardableResult
  func tag(_ tag: Int) -> Self {
    menuItem.tag = tag
    return self
  }

  @discardableResult
  func keyEquivalent(_ key: String) -> Self {
    menuItem.keyEquivalent = key
    return self
  }

  @discardableResult
  func submenu(_ menu: NSMenu) -> Self {
    menuItem.submenu = menu
    return self
  }

  // MARK: - Build

  func build() -> NSMenuItem {
    if let handler = selectHandler {
      menuItem.target = Invoker.shared
      menuItem.action = #selector(Invoker.execute(_:))
      // Store handler and subscriptions to keep them alive
      menuItem.representedObject = (handler, subscriptions)
    }
    return menuItem
  }
}

// MARK: - Invoker

private extension MenuItemBuilder {
  final class Invoker {
    static let shared = Invoker()

    private init() {}

    @objc
    func execute(_ item: NSMenuItem) {
      guard let (handler, _) = item.representedObject as? (() -> Void, Set<AnyCancellable>) else {
        return
      }
      handler()
    }
  }
}
