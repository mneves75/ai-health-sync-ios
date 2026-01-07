#!/usr/bin/env bash
# scripts/docs/check-links.sh
#
# Check all Markdown documentation for broken links
# Part of living documentation automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Checking Documentation Links ==="
echo ""

# Counters
total_files=0
total_links=0
broken_links=0

# Find all markdown files in DOCS directory
echo "🔍 Scanning documentation files..."
mapfile -t md_files < <(find DOCS -name "*.md" -type f)

for file in "${md_files[@]}"; do
    total_files=$((total_files + 1))

    # Extract all markdown links: [text](url)
    mapfile -t links < <(grep -oP '\[([^\]]+)\]\(([^)]+)\)' "$file" | grep -oP '\(([^)]+)\)' | tr -d '()')

    for link in "${links[@]}"; do
        total_links=$((total_links + 1))

        # Skip anchor links
        if [[ "$link" =~ ^# ]]; then
            continue
        fi

        # Check if it's a relative link (local file)
        if [[ ! "$link" =~ ^https?:// ]]; then
            # Resolve relative path
            target_path="$(dirname "$file")/$link"

            if [[ ! -f "$target_path" ]]; then
                echo -e "${RED}✗ BROKEN:${NC} $file -> $link"
                broken_links=$((broken_links + 1))
            fi
        fi
    done
done

echo ""
echo "=== Link Check Summary ==="
echo "Files scanned: $total_files"
echo "Links checked: $total_links"
echo -e "Broken links: ${RED}$broken_links${NC}"
echo ""

if [ $broken_links -gt 0 ]; then
    echo -e "${RED}❌ Found broken links!${NC}"
    echo "Please fix the broken links listed above."
    exit 1
else
    echo -e "${GREEN}✅ All links are valid!${NC}"
    exit 0
fi
