//
//  UpdateSetting.swift
//  FinderSnap
//
//  Created by Eden on 2024/12/10.
//

import Cocoa
import MarkdownUI
import SettingsKit
import SwiftUI

// MARK: - Update Setting Pane

struct UpdateSettingPane: SettingsPane {
  var tabViewImage: NSImage? {
    NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle", accessibilityDescription: nil)
  }

  var preferredTitle: String {
    String(localized: "Update")
  }

  var view: some View {
    UpdateSettingView(state: .shared, checker: .shared)
      .frame(width: GeneralSettingView.Layout.settingsPaneWidth)
  }
}

// MARK: - Update Setting View

struct UpdateSettingView: View {
  @ObservedObject var state: AppState
  @ObservedObject var checker: UpdateChecker

  @State private var checkMessage: String?
  @State private var showChangelog = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      updateSection
      Divider()
      settingsSection
      Divider()
      installationSection
    }
    .padding()
    .sheet(isPresented: $showChangelog) {
      ChangelogSheet(checker: checker)
    }
  }

  // MARK: - Update Section

  @ViewBuilder
  private var updateSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Status display
      if checker.updateAvailable, let latest = checker.latestRelease {
        // Update available state
        HStack(spacing: 5) {
          Image(systemName: "arrow.down.circle.fill")
            .foregroundColor(.accentColor)
            .font(.system(size: 22))

          Text("Version \(latest.tagName) Available")
            .font(.headline)

          Spacer()

          HStack(spacing: 15) {
            Button("What's New") {
              showChangelog = true
            }
            Button("Skip This Version") {
              checker.dismissCurrentUpdate()
            }
          }
        }
      } else {
        // Up to date state
        HStack(spacing: 5) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
            .font(.system(size: 22))

          Text("You're up to date")
            .font(.headline)
        }
      }

      // Check button and message
      HStack(spacing: 12) {
        Button(action: performCheck) {
          if checker.isChecking {
            HStack(spacing: 6) {
              ProgressView()
                .controlSize(.small)
              Text("Checking...")
            }
          } else {
            Text("Check for Updates")
          }
        }
        .disabled(checker.isChecking)

        if let message = checkMessage {
          Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.bottom, 10)
  }

  // MARK: - Settings Section

  @ViewBuilder
  private var settingsSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Toggle("Automatically check for updates", isOn: $state.autoCheckUpdates)

      if state.autoCheckUpdates {
        Picker("Check interval:", selection: $state.checkInterval) {
          Text("Daily")
            .tag(AppState.UpdateCheckInterval.daily)
          Text("Weekly")
            .tag(AppState.UpdateCheckInterval.weekly)
        }
        .fixedSize()
        .padding(.leading, 20)
      }

      Toggle("Include pre-release versions", isOn: $state.includePrerelease)

      Text("Pre-release versions may include beta features that are still in development.")
        .font(.system(size: 11))
        .foregroundColor(.secondary)
        .padding(.leading, 20)
    }
    .padding(.vertical, 10)
  }

  // MARK: - Installation Section

  @ViewBuilder
  private var installationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Installation Options")
        .font(.headline)

      Button {
        checker.openReleasePage()
      } label: {
        Label("Download from GitHub", systemImage: "arrow.down.circle")
      }
      .disabled(!checker.updateAvailable)

      Text("Or update via Homebrew:")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.top, 4)

      VStack(alignment: .leading, spacing: 4) {
        homebrewCommandRow("brew tap LZhenHong/tap")
        homebrewCommandRow("brew install --cask findersnap")
      }
    }
    .padding(.top, 10)
  }

  @ViewBuilder
  private func homebrewCommandRow(_ command: String) -> some View {
    HStack {
      Text(command)
        .font(.system(size: 11, design: .monospaced))
        .padding(6)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )

      Button {
        copyToClipboard(command)
      } label: {
        Image(systemName: "doc.on.doc")
      }
      .buttonStyle(.borderless)
      .help("Copy to clipboard")
    }
  }

  // MARK: - Actions

  private func performCheck() {
    checkMessage = nil
    Task {
      do {
        try await checker.checkForUpdates()
      } catch {
        checkMessage = error.localizedDescription
      }
    }
  }

  private func copyToClipboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
}

// MARK: - Changelog Sheet

struct ChangelogSheet: View {
  @ObservedObject var checker: UpdateChecker
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading) {
          Text("What's New")
            .font(.headline)
          if let release = checker.latestRelease {
            Text(release.tagName)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        Spacer()
        Button("Done") {
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
      .padding()

      Divider()

      if let changelog = checker.changelog {
        ScrollView {
          Markdown(changelog)
            .markdownTextStyle(\.text) {
              FontSize(13)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
      } else {
        Text("No changelog available")
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(width: 500, height: 400)
  }
}

#Preview {
  UpdateSettingView(state: .shared, checker: .shared)
    .frame(width: GeneralSettingView.Layout.settingsPaneWidth)
}
