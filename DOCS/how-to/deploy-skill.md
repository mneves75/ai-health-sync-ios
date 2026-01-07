# Deploy Skill: Share the HealthKit Sync Agent Skill
**Install and distribute the agentskills.io compatible skill**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Git installed
- [ ] Access to target AI coding tool

---

## What You'll Accomplish

By the end of this guide, you'll have the HealthKit Sync skill installed in your preferred AI coding assistant, enabling it to understand CLI commands, security patterns, and project architecture.

---

## Understanding Agent Skills

[Agent Skills](https://agentskills.io) is an open specification for sharing knowledge with AI coding assistants. Skills provide:

- **Context** - Domain-specific knowledge
- **Commands** - Tool-specific syntax
- **Patterns** - Best practices and conventions
- **References** - Deep documentation on demand

The HealthKit Sync skill teaches AI assistants about:
- CLI commands (`healthsync fetch`, `healthsync scan`, etc.)
- mTLS security patterns
- Swift 6 concurrency in the codebase
- Project architecture

---

## Option A: Claude Code (Automatic)

Skills in the `skills/` directory are automatically loaded when Claude Code runs from the repository root.

```bash
# Navigate to project
cd /path/to/ai-health-sync-ios

# Start Claude Code - skill is auto-loaded
claude
```

**Verify:**
```
You: What CLI commands are available?
Claude: Based on the healthkit-sync skill, the available commands are...
```

---

## Option B: ClawdBot

### Symlink (Recommended)

Stays synchronized with repository updates:

```bash
# Create skills directory if needed
mkdir -p ~/.clawdbot/skills

# Symlink the skill
ln -s "$(pwd)/skills/healthkit-sync" ~/.clawdbot/skills/healthkit-sync

# Restart ClawdBot gateway
clawdbot restart
```

### Copy

For offline or isolated use:

```bash
mkdir -p ~/.clawdbot/skills
cp -r skills/healthkit-sync ~/.clawdbot/skills/
```

---

## Option C: Cursor

```bash
# Create skills directory
mkdir -p ~/.cursor/skills

# Copy skill
cp -r skills/healthkit-sync ~/.cursor/skills/

# Restart Cursor to load
```

---

## Option D: Goose

```bash
# Create skills directory
mkdir -p ~/.goose/skills

# Copy skill
cp -r skills/healthkit-sync ~/.goose/skills/

# Restart Goose
```

---

## Option E: Other Tools

For any agentskills.io compatible tool:

1. Find the tool's skills directory (check documentation)
2. Copy the `skills/healthkit-sync` folder there
3. Restart the tool

---

## Sharing Your Skill

### Via GitHub (Current)

The skill is already available at:
```
https://github.com/mneves75/ai-health-sync-ios/tree/master/skills/healthkit-sync
```

Users can install with:
```bash
# Clone just the skill (sparse checkout)
git clone --filter=blob:none --sparse https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
git sparse-checkout set skills/healthkit-sync

# Copy to their tools
cp -r skills/healthkit-sync ~/.cursor/skills/
```

### Via NPM (Optional)

Package and publish to NPM:

```bash
# Create package.json in skill directory
cat > skills/healthkit-sync/package.json << 'EOF'
{
  "name": "@mneves75/skill-healthkit-sync",
  "version": "1.0.0",
  "description": "Agent skill for iOS HealthKit sync CLI",
  "keywords": ["agentskills", "healthkit", "ios", "cli"],
  "repository": "https://github.com/mneves75/ai-health-sync-ios",
  "license": "Apache-2.0",
  "files": ["SKILL.md", "references/", "TESTING.md"]
}
EOF

# Publish
cd skills/healthkit-sync
npm publish --access public
```

Users install with:
```bash
npm install -g @mneves75/skill-healthkit-sync
# Then copy to their tool's skills directory
```

### Via Direct Download

Users can download individual files:
```bash
# Download SKILL.md
curl -O https://raw.githubusercontent.com/mneves75/ai-health-sync-ios/master/skills/healthkit-sync/SKILL.md

# Download references
mkdir -p references
curl -o references/CLI-REFERENCE.md https://raw.githubusercontent.com/mneves75/ai-health-sync-ios/master/skills/healthkit-sync/references/CLI-REFERENCE.md
curl -o references/SECURITY.md https://raw.githubusercontent.com/mneves75/ai-health-sync-ios/master/skills/healthkit-sync/references/SECURITY.md
curl -o references/ARCHITECTURE.md https://raw.githubusercontent.com/mneves75/ai-health-sync-ios/master/skills/healthkit-sync/references/ARCHITECTURE.md
```

---

## Verify Installation

After installing, test that the skill is loaded:

```
You: What is the healthkit-sync skill about?
AI: The healthkit-sync skill provides knowledge about the iOS Health Sync
    project, including CLI commands, mTLS security patterns, and Swift 6
    architecture...
```

```
You: How do I fetch step data?
AI: Use the healthsync fetch command:
    healthsync fetch --types steps --start 2026-01-01
```

---

## Skill Structure

```
skills/healthkit-sync/
├── SKILL.md              # Main skill (loaded first)
├── TESTING.md            # Test patterns
└── references/
    ├── CLI-REFERENCE.md  # Detailed CLI docs
    ├── SECURITY.md       # mTLS patterns
    └── ARCHITECTURE.md   # Project structure
```

| File | Size | Purpose |
|------|------|---------|
| SKILL.md | ~150 lines | Core knowledge, always loaded |
| references/* | ~400 lines | Deep dives, loaded on-demand |

---

## Updating the Skill

### If Symlinked

Updates are automatic when you `git pull`:
```bash
cd /path/to/ai-health-sync-ios
git pull origin master
# Skill is updated immediately
```

### If Copied

Re-copy after updates:
```bash
cd /path/to/ai-health-sync-ios
git pull origin master
cp -r skills/healthkit-sync ~/.cursor/skills/
```

---

## Troubleshooting

### Skill Not Loading

1. **Check path:** Ensure skill is in correct directory
2. **Check structure:** Must have `SKILL.md` at root
3. **Restart tool:** Most tools require restart to load new skills

### References Not Loading

References are loaded on-demand when the AI needs them. If they're not being used:

1. Ask specifically: "Show me the CLI reference for healthsync"
2. Check file permissions: `ls -la skills/healthkit-sync/references/`

### Wrong Tool Directory

Find your tool's skills directory:

| Tool | Default Path |
|------|-------------|
| Claude Code | `./skills/` (project-local) |
| ClawdBot | `~/.clawdbot/skills/` |
| Cursor | `~/.cursor/skills/` |
| Goose | `~/.goose/skills/` |

---

## Related Documentation

- **[Agent Skills Specification](https://agentskills.io/specification)** - Official spec
- **[skills/README.md](../../skills/README.md)** - Local skills documentation
- **[CLI Reference](../../skills/healthkit-sync/references/CLI-REFERENCE.md)** - Full CLI docs

---

*Last updated: 2026-01-07*
