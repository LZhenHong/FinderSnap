#!/bin/bash
# Common variables and functions for release scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project paths
[ -z "$SCRIPT_DIR" ] && SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT="$PROJECT_ROOT/FinderSnap/FinderSnap.xcodeproj"
SCHEME="FinderSnap"
PRODUCT_NAME="FinderSnap"
BUILD_DIR="$PROJECT_ROOT/build"
RELEASE_DIR="$PROJECT_ROOT/releases"

# Logging
print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Get app version from Xcode project
get_version() {
    xcodebuild -project "$XCODE_PROJECT" -showBuildSettings -scheme "$SCHEME" 2>/dev/null \
        | grep "MARKETING_VERSION" | head -1 | awk '{print $3}'
}

# Get previous tag or first commit hash
get_previous_ref() {
    git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD
}

# Get commits since ref
get_commits() {
    local ref=$1
    if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
        git log --pretty=format:"- %s" --no-merges
    else
        git log "$ref"..HEAD --pretty=format:"- %s" --no-merges
    fi
}

# Get diff since ref
get_diff() {
    local ref=$1
    echo "=== Changed Files ==="
    if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
        git diff --stat "$ref" HEAD | tail -20
        echo -e "\n=== Code Changes ==="
        git diff "$ref" HEAD --no-color -- '*.swift' | head -500
    else
        git diff --stat "$ref"..HEAD | tail -20
        echo -e "\n=== Code Changes ==="
        git diff "$ref"..HEAD --no-color -- '*.swift' | head -500
    fi
}
