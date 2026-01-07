# Progressive Disclosure in Documentation

**Making complex information digestible**

---

## Overview

Progressive disclosure is a design principle that shows only the information a user needs at the moment they need it. This reduces cognitive load and helps users focus on their immediate goal.

---

## Why Progressive Disclosure Matters

**Based on 2025 research from [FluidTopics](https://www.fluidtopics.com/blog/industry-insights/technical-documentation-trends-2025/):**

- Users scan documentation, they don't read word-for-word
- Wall-of-text overwhelms readers and causes abandonment
- Simple first, complex later leads to 40% higher success rates

---

## Techniques

### 1. Expandable Sections

Use `<details>` and `<summary>` HTML tags (supported by most Markdown renderers):

```html
<details>
<summary>📖 Advanced: Custom Certificate Configuration</summary>

If you need to use custom certificates instead of auto-generated ones...

[Detailed content here]

</details>
```

**Result:**
<details>
<summary>📖 Advanced: Custom Certificate Configuration</summary>

If you need to use custom certificates instead of auto-generated ones, you can provide your own TLS identity:

```swift
let customIdentity = try TLSIdentity(
    certificate: myCertificate,
    privateKey: myPrivateKey
)

let server = NetworkServer(
    identityProvider: { customIdentity }
)
```

**Note:** Custom certificates require manual fingerprint verification during pairing.
</details>

---

### 2. "Click for More" Links

Link to detailed sections from summaries:

```markdown
**Basic Usage:**

Run `healthsync fetch --types steps` to get your steps data.

**[▼ Click for advanced fetching options](#advanced-fetching)**
```

Then later in the document:

```markdown
## Advanced Fetching Options

<details>
<summary>Show advanced options</summary>

### Date Range Queries
### Multiple Data Types
### Pagination
### Custom Formats
</details>
```

---

### 3. Separate "Just the Basics" from "Deep Dives"

Structure your documentation with clear complexity levels:

```markdown
## Quick Start (Basics)

Get running in 10 minutes with these 3 steps...

---

## Understanding How It Works (Deep Dive)

Learn about the architecture and design decisions...

<details>
<summary>🎓 Academic: Security Proofs and Formal Verification</summary>

For readers interested in formal methods...

</details>
```

---

### 4. Tooltips and Hover Text

In HTML/JS documentation:

```html
<span class="tooltip" data-tooltip="TLS 1.3 is the latest version, providing better security and performance than TLS 1.2">
  TLS 1.3
</span>
```

---

### 5. Tabs for Alternative Approaches

```markdown
## Installation

**Choose your preferred method:**

- **[Homebrew](#homebrew-install)** - Recommended for Mac users
- **[Binary Download](#binary-download)** - Standalone executable
- **[From Source](#from-source)** - For developers

### Homebrew Install

[Homebrew instructions...]

### Binary Download

[Download instructions...]

### From Source

[Source build instructions...]
```

---

## Examples in Our Documentation

### Quick Start Guide

**Progression:**
1. Prerequisites (brief list)
2. 3 basic steps to get running
3. `<details>` sections for troubleshooting
4. Links to deeper guides

### Architecture Diagrams

**Basic diagram first** (components and connections), then:

```html
<details>
<summary>📊 Advanced: Detailed Class Hierarchy</summary>

[Full UML class diagram with all methods and properties]

</details>
```

### API Documentation

**Simple example first:**

```swift
let service = HealthKitService()
let data = await service.fetchSamples(...)
```

**Then, with `<details>`:**

- All parameters explained
- Return value details
- Error conditions
- Advanced usage patterns
- Performance characteristics

---

## Writing Guidelines

### DO ✅

- Start with the simplest possible example
- Add complexity incrementally
- Use expandable sections for optional details
- Link to related content
- Mark advanced content clearly

### DON'T ❌

- Dump all information at once
- Hide critical information in expandable sections
- Make users click to see the basics
- Bury the answer under 3 levels of disclosure
- Use misleading labels

---

## Testing Progressive Disclosure

**Review your documentation:**

1. Can a new user complete the basic task in under 2 minutes?
2. Is the first screen/half-page simple and approachable?
3. Can experts quickly jump to advanced details?
4. Do expandable sections work in your Markdown renderer?
5. Have you tested with real users?

---

## Accessibility Considerations

- **Screen readers:** `<details>`/`<summary>` is well-supported
- **Keyboard navigation:** Ensure expandable sections are keyboard-accessible
- **Clear labels:** Don't use "Click here" - use "Show advanced options"
- **Persistent state:** Consider saving user's expansion preferences (requires JS/cookies)

---

## Tools

### Markdown Renderers

Check if your renderer supports `<details>`:

| Platform | `<details>` Support |
|----------|-------------------|
| GitHub | ✅ Yes |
| GitLab | ✅ Yes |
| Docusaurus | ✅ Yes |
| Hugo | ✅ Yes |
| MkDocs | ✅ With extension |
| Standard Markdown | ❌ No |

### HTML Documentation Sites

If using HTML/JS:

- **Bootstrap Collapse** - Bootstrap components
- **Alpine.js** - Lightweight interactivity
- **HTMX** - Progressive enhancement
- **Details/Summary** - Native HTML (recommended)

---

## See Also

- **[Writing Guide](./contributing/documentation.md)** - Documentation standards
- **[Accessibility Guide](./ACCESSIBILITY.md)** - WCAG compliance
- **[Diataxis Framework](https://diataxis.fr/)** - Documentation methodology

---

**Progressive Disclosure Guide Version:** 1.0.0
**Last Updated:** 2026-01-07
