//
//  AboutSetting.swift
//  FinderSnap
//
//  Created by Eden on 2024/5/6.
//

#if !DISABLE_UPDATE_CHECK
  import AppUpdater
#endif

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
  #if !DISABLE_UPDATE_CHECK
    @ObservedObject private var updater = AppUpdater(owner: "LZhenHong", repo: "FinderSnap")
  #endif
  @State private var isChecking = false
  @State private var checkMessage: String?

  var displayVersion: String {
    "\(Bundle.main.appVersion ?? "1.0.0") (\(Bundle.main.buildVersion ?? "1"))"
  }

  #if !DISABLE_UPDATE_CHECK
    private var hasDownloadedUpdate: Bool {
      if case .downloaded = updater.state { return true }
      return false
    }

    @ViewBuilder
    var checkingView: some View {
      HStack(spacing: 6) {
        ProgressView()
          .controlSize(.small)
        Text("Checking for updates...")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }

    @ViewBuilder
    var newUpdateView: some View {
      VStack(spacing: 6) {
        Text("A new version is ready to install")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button {
          updater.install()
        } label: {
          Text("Install Update")
        }
      }
    }

    @ViewBuilder
    var checkUpdateView: some View {
      Button {
        checkForUpdates()
      } label: {
        Text("Check for Updates")
      }
    }

    @ViewBuilder
    var updateCheckView: some View {
      VStack(spacing: 8) {
        if isChecking {
          checkingView
        } else if hasDownloadedUpdate {
          newUpdateView
        } else {
          checkUpdateView
        }

        if let message = checkMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }

    private func checkForUpdates() {
      isChecking = true
      checkMessage = nil

      updater.check(
        success: {
          isChecking = false
          if case .none = updater.state {
            checkMessage = String(localized: "You're up to date")
          }
        },
        fail: { error in
          isChecking = false
          checkMessage = error.localizedDescription
        }
      )
    }
  #endif

  var body: some View {
    VStack {
      Image(nsImage: NSApp.applicationIconImage)
      Text(Bundle.main.appName ?? "FinderSnap")
        .font(.title)
        .fontWeight(.bold)
      Text("Version: \(displayVersion)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      #if !DISABLE_UPDATE_CHECK
        updateCheckView
          .padding(.top, 8)
      #endif

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
