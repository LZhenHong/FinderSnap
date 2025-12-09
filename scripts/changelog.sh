#!/bin/bash
# Generate changelog using DeepSeek AI
# Usage: ./changelog.sh [--diff]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Load .env if exists
[[ -f "$PROJECT_ROOT/.env" ]] && source "$PROJECT_ROOT/.env"

: "${DEEPSEEK_BASE_URL:=https://api.deepseek.com}"
: "${DEEPSEEK_MODEL:=deepseek-chat}"

USE_DIFF=false
[[ "$1" == "--diff" ]] && USE_DIFF=true

# DeepSeek API call
call_api() {
    local prompt=$1
    local body=$(jq -n --arg m "$DEEPSEEK_MODEL" --arg p "$prompt" \
        '{model:$m, messages:[{role:"user",content:$p}], stream:false}')

    local resp=$(curl -s "${DEEPSEEK_BASE_URL}/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
        -d "$body")

    if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
        print_error "API: $(echo "$resp" | jq -r '.error.message // "Unknown"')"
        return 1
    fi
    echo "$resp" | jq -r '.choices[0].message.content // empty'
}

# Generate English changelog
generate_english() {
    local content=$1 version=$2 date=$3 mode=$4

    local source_desc="Git commits"
    [[ "$mode" == "diff" ]] && source_desc="Code changes"

    call_api "Write release notes for FinderSnap (macOS menu bar app that auto-resizes Finder windows).

For END USERS only:
- Only user-visible features, max 5-6 items
- Skip technical changes (refactoring, dependencies)
- Simple language, focus on benefits

$source_desc:
$content

Format:
# Changelog

## [$version] - $date

### Changes

✨ **New**
- (features)

🔧 **Improved**
- (improvements)

🐛 **Fixed**
- (fixes)

Skip empty categories. One sentence per item."
}

# Translate to Chinese
translate() {
    local content=$1 variant=$2
    local instruction="Translate to Simplified Chinese (简体中文)."
    [[ "$variant" == "traditional" ]] && \
        instruction="Translate to Traditional Chinese (繁體中文), Taiwan terms (視窗/設定)."

    call_api "$instruction

Translate exactly, keep structure. Translate headers (New→新增, Improved→改进/改進, Fixed→修复/修復).
Keep emojis and markdown.

$content"
}

# Fallback
fallback() {
    local v=$1 d=$2 l=$3
    case $l in
        en)      echo -e "# Changelog\n\n## [$v] - $d\n\n- Initial release" ;;
        zh-Hans) echo -e "# 更新日志\n\n## [$v] - $d\n\n- 首次发布" ;;
        zh-Hant) echo -e "# 更新日誌\n\n## [$v] - $d\n\n- 首次發佈" ;;
    esac
}

main() {
    [[ -z "$DEEPSEEK_API_KEY" ]] && { print_error "DEEPSEEK_API_KEY not set"; exit 1; }

    cd "$PROJECT_ROOT"
    local version=$(get_version) date=$(date "+%Y-%m-%d")
    local prev=$(get_previous_ref)
    local mode="log" content=""

    if $USE_DIFF; then
        mode="diff"
        content=$(get_diff "$prev")
        print_info "Mode: git diff"
    else
        content=$(get_commits "$prev")
        print_info "Mode: git log"
    fi

    print_info "Version: $version"

    local dir="$RELEASE_DIR/$version"
    mkdir -p "$dir"

    # English
    print_info "Generating English..."
    local en=$(generate_english "$content" "$version" "$date" "$mode")
    [[ -n "$en" ]] && echo "$en" > "$dir/CHANGELOG.en.md" && print_success "CHANGELOG.en.md" \
        || { fallback "$version" "$date" "en" > "$dir/CHANGELOG.en.md"; en=$(cat "$dir/CHANGELOG.en.md"); }

    # Simplified Chinese
    print_info "Translating zh-Hans..."
    local zh=$(translate "$en" "simplified")
    [[ -n "$zh" ]] && echo "$zh" > "$dir/CHANGELOG.zh-Hans.md" && print_success "CHANGELOG.zh-Hans.md" \
        || fallback "$version" "$date" "zh-Hans" > "$dir/CHANGELOG.zh-Hans.md"

    # Traditional Chinese
    print_info "Translating zh-Hant..."
    zh=$(translate "$en" "traditional")
    [[ -n "$zh" ]] && echo "$zh" > "$dir/CHANGELOG.zh-Hant.md" && print_success "CHANGELOG.zh-Hant.md" \
        || fallback "$version" "$date" "zh-Hant" > "$dir/CHANGELOG.zh-Hant.md"

    print_success "Done: $dir/"
}

main "$@"
