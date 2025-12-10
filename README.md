# FinderSnap

<p align="center">
  <img src="FinderSnap/FinderSnap/Resources/Assets.xcassets/AppIcon.appiconset/128x128.png" alt="FinderSnap Icon" width="128" height="128">
</p>

<p align="center">
  <strong>Automatically resize and position new Finder windows on macOS</strong>
</p>

<p align="center">
  <a href="https://github.com/LZhenHong/FinderSnap/releases/latest"><img src="https://img.shields.io/github/v/release/LZhenHong/FinderSnap?label=Release" alt="Release"></a>
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

## Features

- Automatically resize and position new Finder windows
- Center windows or place at custom coordinates
- Multi-display support (main screen or active screen)
- Smooth window transition animations
- Smart exclusions for Quick Look and DMG windows

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permission (prompted on first launch)

## Installation

### Homebrew (Recommended)

```bash
brew tap LZhenHong/tap
brew install --cask findersnap
```

### Download from GitHub

Download the latest release from the [Releases](https://github.com/LZhenHong/FinderSnap/releases) page.

### Build from Source

```bash
git clone https://github.com/LZhenHong/FinderSnap.git
cd FinderSnap
xcodebuild -project FinderSnap/FinderSnap.xcodeproj -scheme FinderSnap -configuration Release build
```

The built app will be located in the `build/Release` directory.

### Code Signing Note

This app is open source and safe to use. Since it is not notarized by Apple, macOS Gatekeeper may block it by default. To run FinderSnap, remove the quarantine attribute:

```bash
xattr -cr /path/to/FinderSnap.app
```

Alternatively, build from source to avoid Gatekeeper restrictions.

## Usage

1. **Launch FinderSnap** - The app icon appears in the menu bar
2. **Grant Accessibility Permission** - Required for window manipulation (prompted on first launch)
3. **Configure Settings** - Click the menu bar icon and select "Settings"
4. **Enjoy** - New Finder windows will automatically be resized and positioned

## Development

### Prerequisites

- Xcode 15.0+
- macOS 14.0+

### Build & Run

```bash
# Debug build
xcodebuild -project FinderSnap/FinderSnap.xcodeproj -scheme FinderSnap -configuration Debug build

# Release build
xcodebuild -project FinderSnap/FinderSnap.xcodeproj -scheme FinderSnap -configuration Release build
```

### Release Process

```bash
# Configure API key for AI-powered changelog generation
cp .env.example .env
# Edit .env and add your DEEPSEEK_API_KEY

# Full release (changelog + build + tag)
make release

# Or run steps individually
make changelog       # Generate changelog from git log
make changelog-diff  # Generate changelog from git diff (more accurate)
make build           # Build and package app to releases/<version>/
make tag             # Create git tag
make clean           # Clean build artifacts
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [StorageMacro](https://github.com/LZhenHong/StorageMacro) - Swift macro for UserDefaults persistence
- [SettingsKit](https://github.com/LZhenHong/SettingsKit) - SwiftUI settings window framework
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) - Markdown rendering in SwiftUI

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/LZhenHong">Eden</a>
</p>
