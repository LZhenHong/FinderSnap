#!/bin/bash
# Update Homebrew tap with new version
# Usage: ./homebrew.sh <tap_repo_path>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    # Require tap repo path as argument
    if [[ -z "$1" ]]; then
        print_error "Usage: $0 <tap_repo_path>"
        exit 1
    fi

    local tap_repo="$1"
    if [[ ! -d "$tap_repo" ]]; then
        print_error "Tap repo not found: $tap_repo"
        exit 1
    fi

    cd "$PROJECT_ROOT"

    local version=$(get_version)
    local zip_path="$RELEASE_DIR/$version/$PRODUCT_NAME-$version.zip"

    # Check if ZIP exists
    if [[ ! -f "$zip_path" ]]; then
        print_error "ZIP not found: $zip_path"
        print_info "Run 'make build' first"
        exit 1
    fi

    # Calculate SHA256
    local sha256=$(shasum -a 256 "$zip_path" | awk '{print $1}')
    print_info "Version: $version"
    print_info "SHA256: $sha256"

    # Update cask file
    print_info "Updating Cask..."
    mkdir -p "$tap_repo/Casks"
    cat > "$tap_repo/Casks/findersnap.rb" << EOF
cask "findersnap" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/LZhenHong/FinderSnap/releases/download/#{version}/FinderSnap-#{version}.zip"
  name "FinderSnap"
  desc "Automatically resize and position new Finder windows on macOS"
  homepage "https://github.com/LZhenHong/FinderSnap"

  depends_on macos: ">= :sonoma"

  app "FinderSnap.app"

  zap trash: [
    "~/Library/Preferences/com.lzhlovesjyq.FinderSnap.plist",
  ]
end
EOF

    print_success "Updated: $tap_repo/Casks/findersnap.rb"

    # Commit changes
    cd "$tap_repo"
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "Update FinderSnap to $version"
        print_success "Committed changes"
    else
        print_info "No changes to commit"
    fi
}

main "$@"
