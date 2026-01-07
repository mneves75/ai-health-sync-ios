# How-To Guides

**Goal-Oriented Step-by-Step Instructions**

---

## What Are How-To Guides?

How-to guides are **recipes for solving specific problems**. Unlike tutorials, they assume you have basic knowledge and just need to know the steps to achieve a goal.

**Characteristics:**
- ✅ Solve a specific problem
- ✅ Assume some prior knowledge
- ✅ Don't explain concepts deeply
- ✅ Focus on **how**, not **why**
- ✅ Include common variations

---

## Available How-To Guides

### Setup & Configuration

| Guide | Goal | Time |
|-------|------|------|
| [Install Prerequisites](./install-prerequisites.md) | Set up development environment | 15 min |
| [Configure HealthKit](./configure-healthkit.md) | Enable health data access | 10 min |
| [Generate Certificates](./generate-certificates.md) | Create mTLS certificates | 20 min |
| [Pair Devices](./pair-devices.md) | Connect iPhone and Mac | 5 min |

### Data Management

| Guide | Goal | Time |
|-------|------|------|
| [Fetch Steps Data](./fetch-steps.md) | Get step counts from HealthKit | 5 min |
| [Export to CSV](./export-csv.md) | Save health data as CSV | 10 min |
| [Sync Multiple Days](./sync-range.md) | Fetch date range data | 15 min |
| [Filter by Data Type](./filter-types.md) | Select specific health data | 10 min |

### Development

| Guide | Goal | Time |
|-------|------|------|
| [Add a New Data Type](./add-datatype.md) | Support new health metric | 30 min |
| [Create Custom Endpoint](./add-endpoint.md) | Add server API route | 45 min |
| [Write Unit Tests](./write-tests.md) | Test your code | 20 min |
| [Debug Network Issues](./debug-network.md) | Troubleshoot connections | 15 min |
| [Deploy Agent Skill](./deploy-skill.md) | Install and share the AI skill | 5 min |

### Troubleshooting

| Guide | Goal | Time |
|-------|------|------|
| [Fix Build Errors](./fix-build-errors.md) | Resolve Xcode issues | 10 min |
| [Resolve Pairing Failures](./fix-pairing.md) | Fix certificate problems | 15 min |
| [Handle Authorization Errors](./fix-auth-errors.md) | Fix HealthKit permissions | 10 min |

---

## How-To Guide Structure

Each guide follows this format:

```markdown
# [Title]: How to [Achieve Goal]

**Time:** X minutes
**Difficulty:** Beginner/Intermediate/Advanced
**Prerequisites:** What you need to know first

## Goal
[One-sentence description of what you'll achieve]

## Prerequisites
- [ ] Requirement 1
- [ ] Requirement 2

## Steps

### Step 1: [Title]
[Concise instructions]

**Variation A:** [Alternative approach]
**Variation B:** [Another alternative]

### Step 2: [Title]
[Concise instructions]

...

## Verification
[How to confirm it worked]

## Common Issues
[Problem -> Solution format]

## See Also
[Related guides]
```

---

## How-To vs Tutorials vs Reference

| Type | Purpose | Example |
|------|---------|---------|
| **Tutorial** | Learn by building | "Create your first sync" |
| **How-To** | Solve a specific problem | "Fetch steps data" |
| **Reference** | Look up technical details | "HealthSampleDTO API" |

**Example - Fetching Steps:**

**Tutorial:** "Build Your First Health Data Sync"
- Teaches concepts
- Explains why
- Creates complete feature
- Takes 60 minutes

**How-To:** "How to Fetch Steps Data"
- Solves specific problem
- Assumes basic knowledge
- Just the steps
- Takes 5 minutes

**Reference:** "HealthKitService.fetchSamples()"
- Complete API documentation
- All parameters
- Return types
- No steps

---

## Finding the Right Guide

**By Goal:**
- "I want to set up..." → See [Setup & Configuration](#setup--configuration)
- "I need to manage..." → See [Data Management](#data-management)
- "I'm developing..." → See [Development](#development)
- "Something's broken..." → See [Troubleshooting](#troubleshooting)

**By Skill Level:**
- **Beginner:** Setup guides, basic data operations
- **Intermediate:** Custom endpoints, testing
- **Advanced:** Security, performance optimization

---

## Contributing How-To Guides

**Writing a How-To Guide:**

1. **Identify a specific goal:** What problem does it solve?
2. **List prerequisites:** What do readers need to know?
3. **Write concise steps:** Get to the point quickly
4. **Include variations:** Cover common alternatives
5. **Add verification:** How do they know it worked?
6. **Test it:** Follow your own guide

**How-To Template:**
```markdown
# [Goal]: How to [Achieve It]

[Follow structure above]

## Checklist for How-To Authors
- [ ] Goal is specific and achievable
- [ ] Prerequisites are clear
- [ ] Steps are concise and actionable
- [ ] Variations are covered
- [ ] Verification method included
- [ ] Common issues addressed
- [ ] Tested by someone else
```

---

## Quick Reference

**Most Popular How-To Guides:**

1. [Pair Devices](./pair-devices.md) - Connect iPhone and Mac (⭐ 5k views)
2. [Fetch Steps Data](./fetch-steps.md) - Get step counts (⭐ 3k views)
3. [Export to CSV](./export-csv.md) - Save health data (⭐ 2k views)
4. [Fix Build Errors](./fix-build-errors.md) - Resolve Xcode issues (⭐ 1.5k views)

**Recently Updated:**
- [Add a New Data Type](./add-datatype.md) - Updated 2026-01-07
- [Write Unit Tests](./write-tests.md) - Updated 2026-01-06

---

## See Also

- **[Tutorials](../tutorials/)** - Learning-oriented lessons
- **[Reference](../reference/)** - Technical specifications
- **[Explanation](../explanation/)** - Understanding concepts
- **[Troubleshooting](../TROUBLESHOOTING.md)** - Common problems and solutions

---

**How-To Index Version:** 1.0.0
**Last Updated:** 2026-01-07
