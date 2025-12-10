//
//  AboutSetting.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

import Cocoa
import SettingsKit
import SwiftUI

struct AboutSettingPane: SettingsPane {
  var tabViewImage: NSImage? {
    NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
  }

  var preferredTitle: String {
    String(localized: "About")
  }

  var view: some View {
    AboutSettingView()
  }
}

struct AboutSettingView: View {
  @State private var isChecking = false
  @State private var checkMessage: String?

  var displayVersion: String {
    "\(Bundle.main.appVersion ?? "1.0.0") (\(Bundle.main.buildVersion ?? "1"))"
  }

  var body: some View {
    VStack {
      Image(nsImage: NSApp.applicationIconImage)
      Text(Bundle.main.appName ?? "FinderSnap")
        .font(.title)
        .fontWeight(.bold)
      Text("Version: \(displayVersion)")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button {
        if let url = URL(string: "https://github.com/LZhenHong/FinderSnap/releases") {
          NSWorkspace.shared.open(url)
        }
      } label: {
        Text(String(localized: "Changelog"))
      }
      .buttonStyle(.link)
      .padding(.top, 4)
    }
    .padding(.top, 10)
    .padding(.bottom, 20)
    .frame(width: GeneralSettingView.Layout.settingsPaneWidth)
  }
}
