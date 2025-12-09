# FinderSnap Release Makefile
#
# Environment:
#   DEEPSEEK_API_KEY  - Required for changelog
#   DEEPSEEK_BASE_URL - Optional (default: https://api.deepseek.com)
#   DEEPSEEK_MODEL    - Optional (default: deepseek-chat)

.PHONY: help changelog changelog-diff build tag homebrew release clean

help:
	@echo "Usage:"
	@echo "  make changelog              Generate changelog from git log"
	@echo "  make changelog-diff         Generate changelog from git diff"
	@echo "  make build                  Build and package app"
	@echo "  make tag                    Create git tag"
	@echo "  make homebrew TAP_REPO=path Update Homebrew tap"
	@echo "  make release                Full release (changelog + build + tag)"
	@echo "  make clean                  Clean build artifacts"

changelog:
	@bash scripts/changelog.sh

changelog-diff:
	@bash scripts/changelog.sh --diff

build:
	@bash scripts/build.sh

tag:
	@bash scripts/tag.sh

homebrew:
	@bash scripts/homebrew.sh $(TAP_REPO)

release: changelog build tag
	@echo "\n✅ Release completed!"
	@echo "Next: git push origin <version>"

clean:
	@rm -rf build releases
	@echo "Cleaned"
