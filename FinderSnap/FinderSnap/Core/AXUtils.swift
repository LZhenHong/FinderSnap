//
//  AXUtils.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa
import Combine

enum AXUtils {
  static let trustPublisher = CurrentValueSubject<Bool, Never>(trusted)

  static var trusted: Bool {
    AXIsProcessTrusted()
  }

  @discardableResult
  static func checkIsTrusted() -> Bool {
    guard !trusted else {
      return true
    }

    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
  }

  static func openAccessibilitySetting() {
    guard let url: URL = .accessibilitySettings else { return }
    NSWorkspace.shared.open(url)
  }

  static func checkTrustStatus() {
    debugPrint("ax is trusted: \(trusted)")
    guard trusted != trustPublisher.value else { return }
    trustPublisher.send(trusted)
  }
}

extension String {
  static let accessibilitySettingsPath = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
}

extension URL {
  static let accessibilitySettings = URL(string: .accessibilitySettingsPath)
}
