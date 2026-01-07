# Publishing to ClawdHub

Step-by-step guide to publish the HealthKit Sync skill to [ClawdHub](https://clawdhub.com).

## Prerequisites

- ClawdHub account (sign up at https://clawdhub.com)
- Skill directory with valid `SKILL.md`

## Skill Package Contents

```
healthkit-sync/
├── SKILL.md                    # Required - main skill file
├── TESTING.md                  # Testing documentation
├── HOWTO_CLAWDHUB.md          # This file (exclude from upload)
└── references/
    ├── CLI-REFERENCE.md        # CLI command documentation
    ├── SECURITY.md             # mTLS security patterns
    └── ARCHITECTURE.md         # Project architecture
```

## Step 1: Prepare the Package

Create a zip file excluding unnecessary files:

```bash
cd skills/healthkit-sync

# Create clean zip (exclude this howto file)
zip -r healthkit-sync-1.0.0.zip . \
  -x "HOWTO_CLAWDHUB.md" \
  -x "*.DS_Store" \
  -x "__MACOSX/*"
```

Or manually select files:
```bash
zip -r healthkit-sync-1.0.0.zip \
  SKILL.md \
  TESTING.md \
  references/
```

## Step 2: Fill Out the Form

Navigate to: **https://clawdhub.com/publish**

| Field | Value | Notes |
|-------|-------|-------|
| **Slug** | `healthkit-sync` | Lowercase, hyphens only. Must be unique on ClawdHub. |
| **Display name** | `HealthKit Sync` | Human-readable name shown in listings. |
| **Version** | `1.0.0` | Valid semver (MAJOR.MINOR.PATCH). |
| **Tags** | `latest, healthkit, ios, macos, health` | Comma-separated. Include `latest` for default version. |
| **Changelog** | See below | Optional but recommended. |

### Changelog Content

```
Initial release of HealthKit Sync skill.

Features:
- CLI command reference for healthsync tool
- mTLS security documentation
- iOS/macOS architecture patterns
- QR-based device pairing workflow
- Health data export (CSV/JSON formats)

Compatible with:
- Claude Code
- ClawdBot
- Cursor
- Goose
```

## Step 3: Upload Files

1. Click the upload area or drag-and-drop
2. Select `healthkit-sync-1.0.0.zip` OR the entire `healthkit-sync/` folder
3. Archives auto-extract on upload
4. Verify "SKILL.md required" check turns green

## Step 4: Validation Checks

ClawdHub validates before publishing:

| Check | Requirement | Status |
|-------|-------------|--------|
| Include SKILL.md | Must exist at root | Required |
| 50 MB max per version | Total package size | Required |
| Changelog optional | Describe changes | Recommended |
| Valid semver version | X.Y.Z format | Required |

## Step 5: Publish

Click **Publish** button.

On success, your skill will be available at:
```
https://clawdhub.com/skills/healthkit-sync
```

## Updating the Skill

To publish a new version:

1. Increment version (e.g., `1.0.0` → `1.0.1` or `1.1.0`)
2. Update changelog with new changes
3. Upload new package
4. Update `latest` tag if this should be the default

### Version Guidelines

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fixes, typos | PATCH | 1.0.0 → 1.0.1 |
| New features, docs | MINOR | 1.0.0 → 1.1.0 |
| Breaking changes | MAJOR | 1.0.0 → 2.0.0 |

## Installing from ClawdHub

Once published, users can install via:

### Claude Code / ClawdBot
```bash
clawdbot install healthkit-sync
# or
curl -sL https://clawdhub.com/skills/healthkit-sync/latest.zip | unzip -d ~/.claude/skills/
```

### Manual Installation
```bash
# Download and extract
wget https://clawdhub.com/skills/healthkit-sync/1.0.0.zip
unzip 1.0.0.zip -d ~/.claude/skills/healthkit-sync/
```

## Troubleshooting

### "SKILL.md required" error
- Ensure SKILL.md is at the root of your zip/folder
- Check file is not named `skill.md` (case-sensitive)

### Version conflict
- Each version must be unique
- Cannot overwrite existing versions
- Use a new version number instead

### Upload fails
- Check file size < 50 MB
- Ensure zip is not corrupted: `unzip -t healthkit-sync-1.0.0.zip`
- Try uploading folder directly instead of zip

## Quick Reference

```bash
# Package the skill
cd skills/healthkit-sync
zip -r healthkit-sync-1.0.0.zip SKILL.md TESTING.md references/

# Verify contents
unzip -l healthkit-sync-1.0.0.zip

# Check size
du -sh healthkit-sync-1.0.0.zip
```

## Links

- ClawdHub Publish: https://clawdhub.com/publish
- Agent Skills Spec: https://agentskills.io/specification
- This Project: https://github.com/mneves75/ai-health-sync-ios
