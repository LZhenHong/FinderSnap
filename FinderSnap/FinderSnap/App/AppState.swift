//
//  AppState.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Storage
import SwiftUI

@storage
class AppState: ObservableObject {
  enum WindowPlace: Int {
    case center, custom
  }

  enum WindowScreen: Int {
    case main, current
  }

  enum UpdateCheckInterval: Int {
    case daily, weekly

    var timeInterval: TimeInterval {
      switch self {
      case .daily: 24 * 60 * 60 // 24 hours
      case .weekly: 7 * 24 * 60 * 60 // 7 days
      }
    }
  }

  var resizeWindow = false
  var windowSize: CGSize = .init(width: 1200, height: 800)

  var placeWindow = false
  var place: WindowPlace = .center
  var position: CGPoint = .zero
  var effectFirstWindow = false

  var screen: WindowScreen = .main

  var enableAnimation = true
  var animationDuration: Double = 0.25

  // Update settings
  var autoCheckUpdates = true
  var checkInterval: UpdateCheckInterval = .daily
  var includePrerelease = false
  var lastCheckTimestamp: TimeInterval?
  var dismissedVersion: String?

  var lastCheckDate: Date? {
    get { lastCheckTimestamp.map { Date(timeIntervalSince1970: $0) } }
    set { lastCheckTimestamp = newValue?.timeIntervalSince1970 }
  }

  static let shared = AppState()

  private init() {}
}
