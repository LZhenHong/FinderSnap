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
- **Extensions/** - AXUIElement, CGRect, URL, and Bundle extensions
- **UI/** - Menu bar controller and Settings panes
- **Utilities/** - Menu DSL builders and launch-at-login helper

### Core Components

- **WindowFixer.swift** - Generic AXObserver-based window monitor; watches for `kAXWindowCreatedNotification` on any app by bundle ID
- **FinderWindowFixer.swift** - Finder-specific singleton; determines which windows to resize (excludes Quick Look and DMG windows) and calculates target frames
- **WindowAnimator.swift** - CVDisplayLink-based animator for smooth window transitions with easeOutCubic easing
- **AXUtils.swift** - Accessibility permission checking and status publishing via Combine

### Key Patterns

- Uses macOS Accessibility API (`AXUIElement`, `AXObserver`) to detect and modify windows
- Settings persistence via [StorageMacro](https://github.com/LZhenHong/StorageMacro) (`@storage` macro wraps UserDefaults)
- Menu bar app (LSUIElement = YES) with no dock icon
- Settings window built with SwiftUI using [SettingsKit](https://github.com/LZhenHong/SettingsKit)

### Extensions

- **AXUIElement+.swift** - Generic attribute get/set, window size/position manipulation
- **AXUIElement+Window.swift** - Window type detection (`shouldResize`, `isQuickLookWindow`, `isDiskImageWindow`)
- **CGRect+Accessibility.swift** - Coordinate system conversion (AppKit to Accessibility coordinates)
- **URL+Volume.swift** - Disk image detection for mounted volumes

## Requirements

- macOS 14.0+ (deployment target)
- Accessibility permission required (prompts user on first launch)

## Localization

Supports English, Simplified Chinese (zh-Hans), and Traditional Chinese (zh-Hant). Uses `String(localized:)` for localized strings.
