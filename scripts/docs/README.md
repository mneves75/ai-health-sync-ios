# Documentation Automation Scripts

**Living documentation automation for the iOS Health Sync project**

---

## Overview

These scripts automate documentation quality checks, ensuring the documentation stays accurate, accessible, and up-to-date. They can be run locally or via GitHub Actions CI/CD.

---

## Available Scripts

### check-links.sh

**Purpose:** Validate all internal and external documentation links

**Usage:**
```bash
./scripts/docs/check-links.sh
```

**What it checks:**
- Internal markdown file references
- Relative paths to documentation files
- External links (basic validation)

**Output:**
- Lists all broken links
- Summary of total links checked
- Exit code 1 if broken links found

**Run frequency:** Weekly or before releases

---

### check-code-examples.sh

**Purpose:** Validate syntax of code examples in documentation

**Usage:**
```bash
./scripts/docs/check-code-examples.sh
```

**What it checks:**
- Swift code syntax
- Bash script syntax
- Shell command validity

**Output:**
- Syntax validation results
- Warnings for incomplete snippets

**Note:** Code snippets are often intentionally incomplete (showing just a function), so warnings are informational.

**Run frequency:** Before releases

---

### check-alt-text.sh

**Purpose:** Ensure all images have proper alt text (accessibility)

**Usage:**
```bash
./scripts/docs/check-alt-text.sh
```

**What it checks:**
- All images have alt text
- Alt text is descriptive (not just "image", "diagram")
- Empty alt for decorative images

**Output:**
- Images without alt text
- Images with vague alt text
- WCAG compliance status

**Why it matters:**
- Screen reader users depend on alt text
- Required for WCAG 2.1 AA compliance
- Improves SEO

**Run frequency:** Every documentation change

---

### check-versions.sh

**Purpose:** Detect outdated version references

**Usage:**
```bash
./scripts/docs/check-versions.sh
```

**What it checks:**
- iOS version references
- macOS version references
- Xcode version references
- Swift version references

**Output:**
- Potential outdated version numbers
- Requires manual review

**Update required:** When upgrading project dependencies, update the version constants at the top of this script.

**Run frequency:** Monthly

---

### generate-metrics-report.sh

**Purpose:** Generate comprehensive documentation metrics

**Usage:**
```bash
./scripts/docs/generate-metrics-report.sh
```

**What it reports:**
- Total documentation files
- Total word count
- Code examples count
- Files by section
- Largest files
- Recently updated files
- Potentially orphaned files
- Key documentation coverage

**Output:** Creates `DOCS/metrics-report.md`

**Use cases:**
- Track documentation growth over time
- Identify gaps in coverage
- Review before releases
- Quarterly documentation audits

**Run frequency:** Monthly

---

## GitHub Actions Integration

### Workflow: `.github/workflows/docs-quality.yml`

**Triggers:**
- Push to master/main branches
- Pull requests to master/main
- Scheduled: Daily at 2 AM UTC
- Manual workflow dispatch

**Jobs:**

1. **link-check** - Validates all links
2. **code-examples** - Checks code syntax
3. **markdown-lint** - Lints markdown style
4. **spelling** - Checks spelling
5. **accessibility** - Validates alt text
6. **metrics** - Generates metrics report
7. **summary** - Consolidates results

**Artifacts:**
- Documentation metrics report (available for download)

---

## Running Scripts Locally

### Quick Check (All Scripts)

```bash
# Run all documentation checks
for script in scripts/docs/*.sh; do
    echo "Running: $script"
    chmod +x "$script"
    "$script" || true
done
```

### Individual Checks

```bash
# Check links
./scripts/docs/check-links.sh

# Check code examples
./scripts/docs/check-code-examples.sh

# Check accessibility
./scripts/docs/check-alt-text.sh

# Check versions
./scripts/docs/check-versions.sh

# Generate metrics
./scripts/docs/generate-metrics-report.sh
```

### Before Committing Documentation

```bash
# Pre-commit documentation check
./scripts/docs/check-links.sh && \
./scripts/docs/check-alt-text.sh && \
echo "✅ Documentation checks passed"
```

---

## Pre-Commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run documentation checks on committed files

CHANGED_DOCS=$(git diff --cached --name-only | grep -E '\.md$' || true)

if [ -n "$CHANGED_DOCS" ]; then
    echo "Running documentation checks..."

    ./scripts/docs/check-links.sh || exit 1
    ./scripts/docs/check-alt-text.sh || exit 1

    echo "✅ Documentation checks passed"
fi
```

Install:
```bash
cp .git/hooks/pre-commit.sample .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
# Then add the hook content above
```

---

## Configuration Files

### `.markdownlint.json`

Markdown linting rules (used by GitHub Actions):

```json
{
  "default": true,
  "MD013": false,
  "MD033": false,
  "MD041": false
}
```

**Rules:**
- `MD013`: Line length (disabled for flexibility)
- `MD033`: Inline HTML (allowed for components)
- `MD041`: First line heading (flexible for different doc types)

### `.spellcheck.yml`

Spell checker configuration:

```yaml
matrix:
  - name: Documentation
    sources:
      - DOCS/**/*.md
      - "*.md"
    dictionary:
      wordlists:
        - .wordlist-custom.txt
    ignore_regex:
      - "```.*?```"
      - "~[A-Z]+~"
```

---

## Continuous Improvement

### Weekly

- Review GitHub Actions results
- Fix any failed checks
- Update orphaned files list

### Monthly

- Generate metrics report
- Review documentation coverage
- Update version constants if needed
- Check for outdated content

### Quarterly

- Full documentation audit
- Update learning guide
- Review feedback metrics
- Plan new content

### Before Releases

- Run all checks manually
- Review metrics report
- Update CHANGELOG
- Verify all links work
- Test code examples

---

## Customization

### Adding New Checks

1. Create new script in `scripts/docs/`
2. Make it executable: `chmod +x script.sh`
3. Add job to GitHub Actions workflow
4. Update this README

### Updating Version Constants

Edit `check-versions.sh`:

```bash
# Update these when upgrading
CURRENT_IOS="26.0"
CURRENT_MACOS="15"
CURRENT_XCODE="26.0"
CURRENT_SWIFT="6.0"
CURRENT_BUN="1.2"
```

### Adding to Pre-Commit Hook

Add to `.git/hooks/pre-commit`:

```bash
./scripts/docs/your-new-script.sh || exit 1
```

---

## Troubleshooting

### Script Permissions

**Problem:** `Permission denied` when running scripts

**Solution:**
```bash
chmod +x scripts/docs/*.sh
```

### Missing Dependencies

**Problem:** Script fails with command not found

**Solution:**
```bash
# Install ripgrep (for link checker)
brew install ripgrep  # macOS
sudo apt install ripgrep  # Ubuntu

# Install swift (for code example checker)
# Use Xcode on macOS
# See swift.org for Linux
```

### GitHub Actions Failures

**Problem:** CI fails but local works

**Solution:**
- Check GitHub Actions logs
- Ensure all scripts are executable (`chmod +x`)
- Verify shell shebang (`#!/usr/bin/env bash`)
- Check for macOS-specific commands (use portable alternatives)

---

## Metrics and Goals

### Target Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Broken links | 0 | 0 |
| Missing alt text | 0% | 0% |
| Code examples valid | 100% | 100% |
| Documentation coverage | - | 95%+ |
| Orphaned files | - | <5 |

### Track Progress

Generate monthly metrics reports and compare over time:

```bash
./scripts/docs/generate-metrics-report.sh
git add DOCS/metrics-report.md
git commit -m "docs: update metrics report"
```

---

## Related Documentation

- **[Accessibility Guide](../../DOCS/ACCESSIBILITY.md)** - WCAG compliance
- **[Metrics Guide](../../DOCS/METRICS.md)** - Success metrics
- **[Contributing Guide](../../CONTRIBUTING.md)** - Documentation standards

---

## See Also

- **[GitHub Actions Documentation](https://docs.github.com/en/actions)**
- **[Markdown Lint Rules](https://github.com/DavidAnson/markdownlint)**
- **[WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)**

---

**Automation Scripts Version:** 1.0.0
**Last Updated:** 2025-01-07
