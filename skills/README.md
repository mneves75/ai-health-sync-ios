# Agent Skills

This directory contains [Agent Skills](https://agentskills.io) for AI agents working with this project.

## Available Skills

| Skill | Description |
|-------|-------------|
| [healthkit-sync](./healthkit-sync/) | iOS HealthKit sync CLI commands, security patterns, and architecture |

## Installation

### ClawdBot

Copy or symlink to your ClawdBot skills directory:

```bash
# Option 1: Symlink (recommended - stays in sync with repo)
ln -s "$(pwd)/skills/healthkit-sync" ~/.clawdbot/skills/healthkit-sync

# Option 2: Copy
cp -r skills/healthkit-sync ~/.clawdbot/skills/

# Restart ClawdBot gateway to load the skill
```

### Claude Code

Skills in this directory are automatically available when Claude Code is run from this repository.

### Other Agent Skills Compatible Tools

Copy the skill folder to your tool's skills directory:
- **Cursor**: `~/.cursor/skills/`
- **Goose**: `~/.goose/skills/`
- **OpenCode**: Check tool documentation

## Skill Structure

```
skills/
└── healthkit-sync/
    ├── SKILL.md              # Main skill file (YAML frontmatter + instructions)
    └── references/
        ├── CLI-REFERENCE.md  # Detailed CLI documentation
        ├── SECURITY.md       # mTLS, certificate pinning patterns
        └── ARCHITECTURE.md   # Project structure details
```

## Creating New Skills

Follow the [Agent Skills Specification](https://agentskills.io/specification):

1. Create a folder with lowercase, hyphenated name
2. Add `SKILL.md` with required frontmatter:

```yaml
---
name: skill-name          # Must match folder name
description: Brief description of what the skill does and when to use it
---

# Skill Title

Instructions for the agent...
```

3. Keep `SKILL.md` under 500 lines
4. Use `references/` for detailed documentation (loaded on-demand)

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [ClawdBot Skills Documentation](https://docs.clawd.bot/tools/skills)
