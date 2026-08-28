#!/bin/bash
# Archive, export with Developer ID, notarize, staple and package the app.
# Produces a Gatekeeper-friendly ZIP at releases/<version>/<PRODUCT>-<version>.zip
#
# Prerequisites:
#   - Developer ID Application certificate in the keychain
#   - asc auth configured (App Store Connect API key)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEAM_ID="ND2HQQ895Z"

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

    # Clean
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    # Archive
    print_info "Archiving..."
    xcodebuild -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=macOS" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -archivePath "$BUILD_DIR/$PRODUCT_NAME.xcarchive" \
        -skipMacroValidation \
        archive 2>&1 | grep -E "(error:|\*\*)" || true

    [[ ! -d "$BUILD_DIR/$PRODUCT_NAME.xcarchive" ]] && { print_error "Archive failed"; exit 1; }

    # Export with Developer ID
    print_info "Exporting (Developer ID)..."
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/$PRODUCT_NAME.xcarchive" \
        -exportPath "$BUILD_DIR/Export" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
        -skipMacroValidation 2>&1 | grep -E "(error:|\*\*)" || true

    local app="$BUILD_DIR/Export/$PRODUCT_NAME.app"
    [[ ! -d "$app" ]] && { print_error "Export failed"; exit 1; }

    # Verify Developer ID signature and secure timestamp
    print_info "Verifying signature..."
    codesign -dvvv "$app" 2>&1 | grep -E "Authority|Timestamp" || { print_error "Signature verification failed"; exit 1; }

    # Submit for notarization
    print_info "Submitting for notarization (this may take a few minutes)..."
    local notary_zip="$BUILD_DIR/$PRODUCT_NAME-notary.zip"
    ditto -c -k --keepParent "$app" "$notary_zip"
    asc notarization submit --file "$notary_zip" --wait --output table

    # Staple the ticket so the app passes Gatekeeper offline
    print_info "Stapling..."
    xcrun stapler staple "$app"

    # Gatekeeper assessment
    print_info "Gatekeeper assessment..."
    spctl -a -vv "$app"

    # Package the stapled app
    local out="$RELEASE_DIR/$version"
    mkdir -p "$out"
    rm -f "$out/$PRODUCT_NAME-$version.zip"
    ditto -c -k --sequesterRsrc --keepParent "$app" "$out/$PRODUCT_NAME-$version.zip"

    print_success "Created: $out/$PRODUCT_NAME-$version.zip (Developer ID signed, notarized, stapled)"
}

main "$@"
