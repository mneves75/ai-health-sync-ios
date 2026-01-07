#!/usr/bin/env bash
# scripts/docs/check-versions.sh
#
# Check documentation for outdated version references
# Part of living documentation automation

set -e

# Current versions (update these when upgrading)
CURRENT_IOS="18.0"  # iOS 18 released September 2024
CURRENT_MACOS="15"  # macOS 15 Sequoia
CURRENT_XCODE="16.0"  # Xcode 16 released September 2024
CURRENT_SWIFT="6.0"  # Swift 6.0 in Xcode 16
CURRENT_BUN="1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Checking Documentation Version References ==="
echo ""
echo "Current versions:"
echo "  iOS: $CURRENT_IOS"
echo "  macOS: $CURRENT_MACOS"
echo "  Xcode: $CURRENT_XCODE"
echo "  Swift: $CURRENT_SWIFT"
echo "  Bun: $CURRENT_BUN"
echo ""

# Counters
total_issues=0

# Find all markdown files
mapfile -t md_files < <(find DOCS -name "*.md" -type f)

for file in "${md_files[@]}"; do
    echo "Checking: $file"

    # Check for outdated iOS versions
    outdated_ios=$(grep -n "iOS 2[0-5]\|iOS [0-9]\." "$file" || true)
    if [ -n "$outdated_ios" ]; then
        echo -e "  ${YELLOW}⚠ Potential outdated iOS version:${NC}"
        echo "$outdated_ios" | head -3
        total_issues=$((total_issues + 1))
    fi

    # Check for outdated macOS versions
    outdated_macos=$(grep -n "macOS [0-9]\|macOS 1[0-4]" "$file" || true)
    if [ -n "$outdated_macos" ]; then
        echo -e "  ${YELLOW}⚠ Potential outdated macOS version:${NC}"
        echo "$outdated_macos" | head -3
        total_issues=$((total_issues + 1))
    fi

    # Check for outdated Xcode versions
    outdated_xcode=$(grep -n "Xcode 2[0-5]\|Xcode [0-9]\." "$file" || true)
    if [ -n "$outdated_xcode" ]; then
        echo -e "  ${YELLOW}⚠ Potential outdated Xcode version:${NC}"
        echo "$outdated_xcode" | head -3
        total_issues=$((total_issues + 1))
    fi

    # Check for outdated Swift versions
    outdated_swift=$(grep -n "Swift 5\.[0-9]" "$file" || true)
    if [ -n "$outdated_swift" ]; then
        # Only flag if it's claiming to be current/recommended
        if echo "$outdated_swift" | grep -q "current\|latest\|recommended"; then
            echo -e "  ${YELLOW}⚠ Potential outdated Swift version:${NC}"
            echo "$outdated_swift" | head -3
            total_issues=$((total_issues + 1))
        fi
    fi
done

echo ""
echo "=== Version Check Summary ==="
echo "Potential issues found: $total_issues"
echo ""

if [ $total_issues -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Some version references may be outdated${NC}"
    echo ""
    echo "Manual review required:"
    echo "  1. Check each flagged reference"
    echo "  2. Update if outdated"
    echo "  3. Keep if it's describing historical versions"
    echo "  4. Update this script's version constants when upgrading"
    exit 0
else
    echo -e "${GREEN}✅ No obvious version issues found${NC}"
    exit 0
fi
