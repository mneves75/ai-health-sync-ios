#!/bin/bash
# Copyright 2026 Marcus Neves
# SPDX-License-Identifier: Apache-2.0
#
# package-clawdhub.sh - Package a skill for ClawdHub publishing
#
# Usage: ./scripts/package-clawdhub.sh [options] [version]
#
# Options:
#   -h, --help      Show this help message
#   -n, --dry-run   Show what would be packaged without creating zip
#   -s, --skill     Skill name (default: healthkit-sync)
#
# Examples:
#   ./scripts/package-clawdhub.sh 1.0.0
#   ./scripts/package-clawdhub.sh --dry-run 1.0.0
#   ./scripts/package-clawdhub.sh -s my-skill 2.0.0

set -euo pipefail

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Configuration
SKILL_NAME="healthkit-sync"
OUTPUT_DIR="dist"
MAX_SIZE_MB=50
DRY_RUN=false

# Functions
usage() {
    cat << EOF
${BOLD}Usage:${NC} $0 [options] [version]

Package a skill for ClawdHub publishing.

${BOLD}Options:${NC}
  -h, --help      Show this help message
  -n, --dry-run   Show what would be packaged without creating zip
  -s, --skill     Skill name (default: $SKILL_NAME)

${BOLD}Examples:${NC}
  $0 1.0.0
  $0 --dry-run 1.0.0
  $0 -s my-skill 2.0.0

${BOLD}Requirements:${NC}
  - SKILL.md must exist in skill directory
  - Version must be valid semver (X.Y.Z)
  - Package must be under ${MAX_SIZE_MB}MB

${BOLD}More info:${NC} https://clawdhub.com/publish
EOF
}

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}Info:${NC} $1"
}

success() {
    echo -e "${GREEN}Success:${NC} $1"
}

validate_semver() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        error "Invalid version format '$version'. Use semver (e.g., 1.0.0, 1.0.0-beta.1)"
    fi
}

check_size() {
    local file="$1"
    local size_bytes
    size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    local size_mb=$((size_bytes / 1024 / 1024))

    if [[ $size_mb -ge $MAX_SIZE_MB ]]; then
        error "Package size (${size_mb}MB) exceeds ClawdHub limit (${MAX_SIZE_MB}MB)"
    fi
}

# Parse arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--skill)
            SKILL_NAME="$2"
            shift 2
            ;;
        -*)
            error "Unknown option: $1. Use --help for usage."
            ;;
        *)
            VERSION="$1"
            shift
            ;;
    esac
done

# Default version
VERSION="${VERSION:-1.0.0}"

# Validate inputs
validate_semver "$VERSION"

SKILL_DIR="skills/${SKILL_NAME}"
OUTPUT_FILE="${OUTPUT_DIR}/${SKILL_NAME}-${VERSION}.zip"

# Verify skill directory exists
if [[ ! -d "$SKILL_DIR" ]]; then
    error "Skill directory not found: ${SKILL_DIR}"
fi

# Verify SKILL.md exists (required by ClawdHub)
if [[ ! -f "${SKILL_DIR}/SKILL.md" ]]; then
    error "SKILL.md not found in ${SKILL_DIR}. This file is required by ClawdHub."
fi

# List files to be packaged
echo -e "\n${BOLD}Packaging ${SKILL_NAME} v${VERSION}${NC}\n"
echo "Files to include:"

cd "$SKILL_DIR"
FILES=$(find . -type f \
    ! -name "HOWTO_CLAWDHUB.md" \
    ! -name ".DS_Store" \
    ! -name "*.zip" \
    ! -path "./.git/*" \
    | sort)

for file in $FILES; do
    size=$(du -h "$file" | cut -f1)
    echo "  $file ($size)"
done
cd - > /dev/null

# Dry run - exit here
if [[ "$DRY_RUN" == true ]]; then
    echo -e "\n${YELLOW}Dry run - no package created${NC}"
    exit 0
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove existing zip if present
rm -f "$OUTPUT_FILE"

# Create zip
info "Creating package..."
cd "$SKILL_DIR"
zip -r "../../${OUTPUT_FILE}" . \
    -x "HOWTO_CLAWDHUB.md" \
    -x "*.DS_Store" \
    -x "__MACOSX/*" \
    -x "*.zip" \
    -x ".git/*" \
    > /dev/null
cd - > /dev/null

# Verify and check size
if [[ ! -f "$OUTPUT_FILE" ]]; then
    error "Failed to create package"
fi

check_size "$OUTPUT_FILE"

SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
success "Package created: ${OUTPUT_FILE} (${SIZE})"

# Verify contents
echo -e "\n${BOLD}Package contents:${NC}"
unzip -l "$OUTPUT_FILE" | grep -E "^\s+[0-9]+" | awk '{print "  " $4}'

# Next steps
cat << EOF

${BOLD}Next steps:${NC}
  1. Go to ${BLUE}https://clawdhub.com/publish${NC}
  2. Fill in:
     ${BOLD}Slug:${NC}         ${SKILL_NAME}
     ${BOLD}Display name:${NC} HealthKit Sync
     ${BOLD}Version:${NC}      ${VERSION}
     ${BOLD}Tags:${NC}         latest, healthkit, ios, macos, health
  3. Upload: ${OUTPUT_FILE}
  4. Click ${GREEN}Publish${NC}
EOF
