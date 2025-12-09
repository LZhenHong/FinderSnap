#!/bin/bash
# Build and package the app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    cd "$PROJECT_ROOT"

    local version=$(get_version)
    local build=$(date "+%y%m%d%H%M")

    print_info "Version: $version (build $build)"

    # Update build number in Xcode project
    print_info "Updating build number..."
    cd "$PROJECT_ROOT/FinderSnap"
    agvtool new-version -all "$build" > /dev/null
    cd "$PROJECT_ROOT"

    # Clean & build
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    print_info "Building..."
    xcodebuild -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -archivePath "$BUILD_DIR/$PRODUCT_NAME.xcarchive" \
        archive 2>&1 | grep -E "(error:|warning:|\*\*)" || true

    [[ ! -d "$BUILD_DIR/$PRODUCT_NAME.xcarchive" ]] && { print_error "Build failed"; exit 1; }

    # Export & zip
    local app="$BUILD_DIR/$PRODUCT_NAME.xcarchive/Products/Applications/$PRODUCT_NAME.app"
    cp -R "$app" "$BUILD_DIR/"

    local out="$RELEASE_DIR/$version"
    mkdir -p "$out"
    cd "$BUILD_DIR"
    ditto -c -k --sequesterRsrc --keepParent "$PRODUCT_NAME.app" "$out/$PRODUCT_NAME-$version.zip"

    print_success "Created: $out/$PRODUCT_NAME-$version.zip"
}

main "$@"
