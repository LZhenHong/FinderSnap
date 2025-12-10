//
//  GitHubRelease.swift
//  FinderSnap
//
//  Created by Eden on 2024/12/10.
//

import Foundation

// MARK: - GitHub Release Model

struct GitHubRelease: Decodable {
  let tagName: String
  let name: String
  let body: String
  let htmlUrl: String
  let prerelease: Bool
  let publishedAt: Date
  let assets: [Asset]

  struct Asset: Decodable {
    let name: String
    let browserDownloadUrl: URL
    let size: Int

    enum CodingKeys: String, CodingKey {
      case name
      case browserDownloadUrl = "browser_download_url"
      case size
    }
  }

  enum CodingKeys: String, CodingKey {
    case tagName = "tag_name"
    case name
    case body
    case htmlUrl = "html_url"
    case prerelease
    case publishedAt = "published_at"
    case assets
  }

  var version: SemanticVersion? {
    SemanticVersion(string: tagName)
  }

  var isPrerelease: Bool {
    prerelease ||
      tagName.contains("-beta") ||
      tagName.contains("-rc") ||
      tagName.contains("-alpha")
  }
}

// MARK: - Semantic Version

struct SemanticVersion: Comparable, CustomStringConvertible {
  let major: Int
  let minor: Int
  let patch: Int
  let prerelease: String?

  var isPrerelease: Bool {
    prerelease != nil
  }

  var description: String {
    var result = "\(major).\(minor).\(patch)"
    if let prerelease {
      result += "-\(prerelease)"
    }
    return result
  }

  init?(string: String) {
    var versionString = string
    if versionString.hasPrefix("v") || versionString.hasPrefix("V") {
      versionString = String(versionString.dropFirst())
    }

    let components: [String]
    let prereleaseString: String?

    if let hyphenIndex = versionString.firstIndex(of: "-") {
      let versionPart = String(versionString[..<hyphenIndex])
      prereleaseString = String(versionString[versionString.index(after: hyphenIndex)...])
      components = versionPart.split(separator: ".").map(String.init)
    } else {
      components = versionString.split(separator: ".").map(String.init)
      prereleaseString = nil
    }

    guard components.count >= 2,
          let majorInt = Int(components[0]),
          let minorInt = Int(components[1])
    else {
      return nil
    }

    major = majorInt
    minor = minorInt
    patch = components.count >= 3 ? Int(components[2]) ?? 0 : 0
    prerelease = prereleaseString
  }

  init(major: Int, minor: Int, patch: Int, prerelease: String? = nil) {
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = prerelease
  }

  static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

    // Handle prerelease comparison
    // A version without prerelease is greater than one with prerelease
    // e.g., 1.0.0 > 1.0.0-beta.1
    switch (lhs.prerelease, rhs.prerelease) {
    case (nil, nil):
      return false
    case (nil, _):
      return false // lhs (stable) > rhs (prerelease)
    case (_, nil):
      return true // lhs (prerelease) < rhs (stable)
    case let (lhsPre?, rhsPre?):
      return lhsPre.localizedStandardCompare(rhsPre) == .orderedAscending
    }
  }

  static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    lhs.major == rhs.major &&
      lhs.minor == rhs.minor &&
      lhs.patch == rhs.patch &&
      lhs.prerelease == rhs.prerelease
  }
}

// MARK: - Bundle Extension

extension Bundle {
  var semanticVersion: SemanticVersion? {
    guard let versionString = appVersion else { return nil }
    return SemanticVersion(string: versionString)
  }
}
