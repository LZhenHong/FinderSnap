#!/bin/bash
# Create git tag for release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    cd "$PROJECT_ROOT"

    local version=$(get_version)
    print_info "Version: $version"

    if git rev-parse "$version" >/dev/null 2>&1; then
        print_warning "Tag $version already exists"
        exit 1
    fi

    git tag -a "$version" -m "Release $version"
    print_success "Created tag: $version"
    echo -e "\nNext: git push origin $version"
}

main "$@"
