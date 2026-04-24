# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FinderSnap is a macOS menu bar application that automatically resizes and repositions new Finder windows. It uses the Accessibility API to monitor Finder window creation and apply user-configured size/position settings.

## Build Commands

```bash
# Build from command line
xcodebuild -project FinderSnap/FinderSnap.xcodeproj -scheme FinderSnap -configuration Debug build

# Build for release
xcodebuild -project FinderSnap/FinderSnap.xcodeproj -scheme FinderSnap -configuration Release build
```

## Release Commands

```bash
make changelog       # Generate changelog from git log (requires DEEPSEEK_API_KEY)
make changelog-diff  # Generate changelog from git diff (more accurate)
make build           # Build and package app to releases/<version>/
make tag             # Create git tag
make release         # Full release (changelog + build + tag)
make clean           # Clean build artifacts
```

Configure API key in `.env` (copy from `.env.example`).

## Architecture

### Directory Structure

Source files are in `FinderSnap/FinderSnap/FinderSnap/`:
- **App/** - Entry point (`main.swift`), `AppDelegate.swift`, `AppState.swift`
- **Core/** - Window monitoring and manipulation logic
- **Extensions/** - AXUIElement, CGRect, URL, Bundle, and RawRepresentable extensions
- **UI/** - Menu bar controller, Settings panes, and Onboarding flow
- **Utilities/** - Menu DSL builders and launch-at-login helper

### Core Components

- **WindowFixer.swift** - Generic AXObserver-based window monitor; watches for `kAXWindowCreatedNotification` on any app by bundle ID
- **FinderWindowFixer.swift** - Finder-specific singleton; determines which windows to resize (excludes Quick Look and DMG windows) and calculates target frames
- **WindowAnimator.swift** - CVDisplayLink-based animator for smooth window transitions with easeOutCubic easing
- **AXUtils.swift** - Accessibility permission checking and status publishing via Combine
- **UpdateChecker.swift** - GitHub release checker with localized changelog support; fetches releases from GitHub API, compares semantic versions, downloads localized `CHANGELOG.<lang>.md` assets
- **GitHubRelease.swift** - GitHub API response models and `SemanticVersion` type for version comparison (handles prerelease tags like `-beta`, `-rc`)
- **OnboardingWindowController.swift** - Manages the onboarding window lifecycle; presents a centered non-resizable window on first launch, holds a strong static reference to prevent deallocation
- **OnboardingView.swift** - SwiftUI onboarding flow with 3 steps (welcome, accessibility permission, quick setup); observes `AXUtils.trustPublisher` for live permission status; applies recommended defaults on completion

### Key Patterns

- Uses macOS Accessibility API (`AXUIElement`, `AXObserver`) to detect and modify windows
- Settings persistence via [StorageMacro](https://github.com/LZhenHong/StorageMacro) (`@storage` macro wraps UserDefaults)
- Menu bar app (LSUIElement = YES) with no dock icon
- Settings window built with SwiftUI using [SettingsKit](https://github.com/LZhenHong/SettingsKit)
- Update checker uses GitHub Releases API directly (no third-party dependencies); supports localized changelogs via release assets
- Onboarding flow shown on first launch only; stores completion flag in `AppState.onboardingCompleted`
- Window fixer initialization is deferred until onboarding completes or permission is granted, with a Combine publisher watching `AXUtils.trustPublisher`

### Extensions

- **AXUIElement+.swift** - Generic attribute get/set, window size/position manipulation
- **AXUIElement+Window.swift** - Window type detection (`shouldResize`, `isQuickLookWindow`, `isDiskImageWindow`)
- **CGRect+Accessibility.swift** - Coordinate system conversion (AppKit to Accessibility coordinates)
- **URL+Volume.swift** - Disk image detection for mounted volumes
- **RawRepresentable+.swift** - JSON-based `RawRepresentable` conformance for `CGSize` and `CGPoint`, enabling UserDefaults storage of geometry types via `StorageMacro`

## AppState

`AppState` is a `@storage` singleton (`AppState.shared`) that holds all user-configurable settings:

- **Window resizing**: `resizeWindow`, `windowSize` (default 1200×800)
- **Window positioning**: `placeWindow`, `place` (center/custom), `position`, `effectFirstWindow`
- **Screen targeting**: `screen` (main/current)
- **Animation**: `enableAnimation`, `animationDuration` (default 0.25s)
- **Updates**: `autoCheckUpdates`, `checkInterval` (daily/weekly), `includePrerelease`, `lastCheckDate`, `dismissedVersion`
- **Onboarding**: `onboardingCompleted` — tracks whether the user has seen the onboarding flow

`applyRecommendedSettings()` applies sensible defaults for first-time users (resize to 1200×800, center on main screen, enable animation).

## Requirements

- macOS 14.0+ (deployment target)
- Accessibility permission required (prompts user on first launch)

## Localization

Supports English, Simplified Chinese (zh-Hans), and Traditional Chinese (zh-Hant). Uses `String(localized:)` for localized strings.

## Design Context

See [docs/design-context.md](docs/design-context.md) for full design principles, user profile, brand personality, and aesthetic direction.
