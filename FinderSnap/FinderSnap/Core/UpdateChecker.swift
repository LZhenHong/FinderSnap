//
//  UpdateChecker.swift
//  FinderSnap
//
//  Created by Eden on 2024/12/10.
//

import Cocoa
import Combine
import Foundation

// MARK: - Update Checker

final class UpdateChecker: ObservableObject {
  static let shared = UpdateChecker()

  // Published state
  @Published var isChecking = false
  @Published var latestRelease: GitHubRelease?
  @Published var updateAvailable = false
  @Published var changelog: String?
  @Published var lastError: Error?

  // Combine publishers for menu bar notification
  let updateAvailablePublisher = CurrentValueSubject<Bool, Never>(false)
  let updateVersionPublisher = CurrentValueSubject<String?, Never>(nil)

  // Configuration
  private let owner = "LZhenHong"
  private let repo = "FinderSnap"
  private let apiBaseURL = "https://api.github.com/repos"

  private var backgroundTask: Task<Void, Never>?

  private init() {}

  // MARK: - Public API

  func checkOnLaunchIfNeeded() {
    let state = AppState.shared
    guard state.autoCheckUpdates else { return }

    let shouldCheck: Bool = if let lastCheck = state.lastCheckDate {
      Date().timeIntervalSince(lastCheck) >= state.checkInterval.timeInterval
    } else {
      true
    }

    guard shouldCheck else { return }

    backgroundTask = Task {
      try? await checkForUpdates()
    }
  }

  @MainActor
  func checkForUpdates() async throws {
    isChecking = true
    lastError = nil
    defer { isChecking = false }

    do {
      let releases = try await fetchReleases()
      let state = AppState.shared

      // Filter releases based on prerelease preference
      let eligibleReleases = state.includePrerelease
        ? releases
        : releases.filter { !$0.isPrerelease }

      guard let latest = eligibleReleases.first,
            let latestVersion = latest.version,
            let currentVersion = Bundle.main.semanticVersion
      else {
        updateAvailable = false
        latestRelease = nil
        return
      }

      let hasUpdate = latestVersion > currentVersion &&
        latest.tagName != state.dismissedVersion

      latestRelease = latest
      updateAvailable = hasUpdate
      updateAvailablePublisher.send(hasUpdate)
      updateVersionPublisher.send(hasUpdate ? latest.tagName : nil)

      // Update last check date
      state.lastCheckDate = Date()

      // Fetch localized changelog if update available
      if hasUpdate {
        await fetchLocalizedChangelog(for: latest)
      }
    } catch {
      lastError = error
      throw error
    }
  }

  func dismissCurrentUpdate() {
    guard let release = latestRelease else { return }
    AppState.shared.dismissedVersion = release.tagName
    updateAvailable = false
    updateAvailablePublisher.send(false)
    updateVersionPublisher.send(nil)
  }

  func openReleasePage() {
    guard let release = latestRelease,
          let url = URL(string: release.htmlUrl)
    else { return }
    NSWorkspace.shared.open(url)
  }

  func openAllReleasesPage() {
    guard let url = URL(string: "https://github.com/\(owner)/\(repo)/releases") else { return }
    NSWorkspace.shared.open(url)
  }

  // MARK: - Private Methods

  private func fetchReleases() async throws -> [GitHubRelease] {
    guard let url = URL(string: "\(apiBaseURL)/\(owner)/\(repo)/releases") else {
      throw UpdateError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw UpdateError.networkError
    }

    guard httpResponse.statusCode == 200 else {
      if httpResponse.statusCode == 403 {
        throw UpdateError.rateLimited
      }
      throw UpdateError.networkError
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      return try decoder.decode([GitHubRelease].self, from: data)
    } catch {
      throw UpdateError.parseError
    }
  }

  @MainActor
  private func fetchLocalizedChangelog(for release: GitHubRelease) async {
    let langCode = Self.resolveChangelogLanguage()

    // Build language priority list (preferred language first, then English fallback)
    var langCodes = [langCode]
    if langCode != "en" {
      langCodes.append("en")
    }

    // Try each language in priority order
    for code in langCodes {
      if let text = await fetchChangelogAsset(for: release, langCode: code) {
        changelog = text
        return
      }
    }

    // Fallback to release body
    changelog = release.body.isEmpty ? nil : release.body
  }

  private func fetchChangelogAsset(for release: GitHubRelease, langCode: String) async -> String? {
    let assetName = "CHANGELOG.\(langCode).md"
    guard let asset = release.assets.first(where: {
      $0.name.lowercased() == assetName.lowercased()
    }) else { return nil }

    guard let data = try? await fetchAssetData(asset),
          let text = String(data: data, encoding: .utf8)
    else { return nil }

    return text
  }

  private func fetchAssetData(_ asset: GitHubRelease.Asset) async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: asset.browserDownloadUrl)
    return data
  }

  private static func resolveChangelogLanguage() -> String {
    let preferredLangs = Locale.preferredLanguages
    for lang in preferredLangs {
      let normalized = lang.lowercased().replacingOccurrences(of: "_", with: "-")
      if normalized.hasPrefix("zh-hans") || normalized.hasPrefix("zh-cn") {
        return "zh-Hans"
      }
      if normalized.hasPrefix("zh-hant") || normalized.hasPrefix("zh-tw") || normalized.hasPrefix("zh-hk") {
        return "zh-Hant"
      }
      if normalized.hasPrefix("en") {
        return "en"
      }
    }
    return "en" // Default fallback
  }
}

// MARK: - Update Error

enum UpdateError: LocalizedError {
  case invalidURL
  case networkError
  case parseError
  case rateLimited
  case noValidRelease

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      String(localized: "Invalid URL")
    case .networkError:
      String(localized: "Network error occurred")
    case .parseError:
      String(localized: "Failed to parse release data")
    case .rateLimited:
      String(localized: "GitHub API rate limit exceeded. Please try again later.")
    case .noValidRelease:
      String(localized: "No valid release found")
    }
  }
}
