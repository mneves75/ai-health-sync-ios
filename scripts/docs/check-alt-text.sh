#!/usr/bin/env bash
# scripts/docs/check-alt-text.sh
#
# Check that all images in documentation have alt text
# Part of living documentation automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Checking Image Alt Text (Accessibility) ==="
echo ""

# Counters
total_images=0
images_with_alt=0
images_without_alt=0

# Find all markdown files
mapfile -t md_files < <(find DOCS -name "*.md" -type f)

for file in "${md_files[@]}"; do
    # Find all image references: ![alt](url)
    mapfile -t images < <(grep -oP '!\[([^\]]*)\]\(([^)]+)\)' "$file")

    for image in "${images[@]}"; do
        total_images=$((total_images + 1))

        # Extract alt text
        alt_text=$(echo "$image" | grep -oP '!\[\K[^\]]*')

        if [ -z "$alt_text" ] || [[ "$alt_text" =~ ^[[:space:]]*$ ]]; then
            echo -e "${RED}✗ MISSING ALT TEXT:${NC} $file"
            echo "  Image: $image"
            images_without_alt=$((images_without_alt + 1))
        else
            # Check if alt text is descriptive (not just "image", "diagram", etc.)
            if [[ "$alt_text" =~ ^(image|diagram|chart|graph|screenshot|pic|picture)$ ]]; then
                echo -e "${YELLOW}⚠ VAGUE ALT TEXT:${NC} $file"
                echo "  Alt text: '$alt_text'"
                echo "  Suggestion: Be more specific about the image content"
                images_without_alt=$((images_without_alt + 1))
            else
                images_with_alt=$((images_with_alt + 1))
            fi
        fi
    done
done

echo ""
echo "=== Alt Text Summary ==="
echo "Total images: $total_images"
echo -e "With alt text: ${GREEN}$images_with_alt${NC}"
echo -e "Without alt text: ${RED}$images_without_alt${NC}"
echo ""

if [ $images_without_alt -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Some images need better alt text${NC}"
    echo "Alt text is important for:"
    echo "  - Screen reader users"
    echo "  - SEO (search engines)"
    echo "  - Users who disable images"
    echo ""
    echo "Tips for good alt text:"
    echo "  • Be specific and descriptive"
    echo "  • Include relevant context"
    echo "  • Keep it concise (usually < 125 characters)"
    echo "  • Don't repeat the caption"
    echo "  • For decorative images, use empty alt: ![](url \"\")"
    exit 0
else
    echo -e "${GREEN}✅ All images have proper alt text!${NC}"
    exit 0
fi
