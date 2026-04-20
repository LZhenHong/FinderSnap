//
//  AXUIElement+Window.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa

// MARK: - Window Type Detection

extension AXUIElement {
  /// Determines if this window should be resized.
  /// Excludes special windows like Quick Look and DMG installer windows.
  var shouldResize: Bool {
    !isQuickLookWindow && !isDiskImageWindow
  }

  var isQuickLookWindow: Bool {
    axSubrole == .quickLookSubrole
  }

  /// Checks if this window displays a mounted disk image (DMG).
  var isDiskImageWindow: Bool {
    guard let title = axTitle else {
      return false
    }

    let volumeURL = URL.volume(named: title)

    // Check if this path exists and is a directory
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: volumeURL.path, isDirectory: &isDirectory),
          isDirectory.boolValue
    else {
      return false
    }

    return volumeURL.isDiskImage
  }
}

// MARK: - Constants

private extension String {
  static let quickLookSubrole = "Quick Look"
}
