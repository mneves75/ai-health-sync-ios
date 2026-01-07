# Accessibility Guide

**Making iOS Health Sync Documentation Inclusive for Everyone**

---

## Commitment to Accessibility

We are committed to making our documentation accessible to everyone, regardless of ability or technology.

**Target:** WCAG 2.1 AA Compliance
**Conformance Level:** AA (Priority 1 & 2)

---

## Quick Accessibility Checklist

For every documentation page:

- [ ] **Images:** All images have alt text
- [ ] **Headings:** Proper heading hierarchy (h1 → h2 → h3)
- [ ] **Links:** Descriptive link text (no "click here")
- [ ] **Color:** Contrast ratio ≥ 4.5:1 for normal text
- [ ] **Code:** Code blocks have language specified
- [ ] **Tables:** Headers marked properly
- [ ] **Lists:** Proper list markup
- [ ] **Language:** Simple, clear English

---

## Accessibility Features

### 1. Alternative Text for Images

**Purpose:** Describe images for screen reader users.

**Guidelines:**

**✅ GOOD - Descriptive:**
```markdown
![Sequence diagram showing iOS app sending health data to Mac via TLS connection](images/data-flow.png)
```

**❌ BAD - Vague:
```markdown
![diagram](images/data-flow.png)
```

**For Decorative Images:**
```markdown
<!-- Empty alt text for decorative images -->
![](images/decoration.png "")
```

**For Complex Images:**
```markdown
![Architecture diagram showing 4 layers: Presentation (SwiftUI), Application (AppState), Business (Services), Data (HealthKit, SwiftData)](images/architecture.png)

**Detailed Description:**
The architecture has four layers. Presentation layer contains SwiftUI views. Application layer contains AppState coordinator. Business layer contains services (HealthKitService, NetworkServer, etc.). Data layer contains HealthKit, SwiftData, Keychain, and Network frameworks. Arrows show data flowing from top to bottom.
```

---

### 2. Proper Heading Structure

**Purpose:** Create navigable document structure.

**Guidelines:**

```markdown
# Main Title (h1) - One per page

## Section Heading (h2) - Main sections

### Subsection (h3) - Subsections

#### Detail (h4) - Rarely needed

##### Minor Detail (h5) - Very rare
```

**✅ GOOD - Logical hierarchy:**
```markdown
# Chapter 3: Swift 6

## Async/Await

### How It Works

#### Example Code
```

**❌ BAD - Skips levels:**
```markdown
# Chapter 3

#### Async/Await  <!-- Skipped h2 and h3 -->
```

---

### 3. Descriptive Link Text

**Purpose:** Make links understandable out of context.

**Guidelines:**

**✅ GOOD - Descriptive:**
```markdown
See the [Quick Start Guide](../QUICKSTART.md) for setup instructions.
Learn more about [pairing devices](../how-to/pair-devices.md).
```

**❌ BAD - Vague:**
```markdown
[Click here](../QUICKSTART.md) for setup.
[More info](../how-to/pair-devices.md).
```

**For URLs:**
```markdown
<https://github.com/your-org/repo>(Repository)  <!-- Add descriptive text -->
```

---

### 4. Color Contrast

**Purpose:** Ensure text is readable for low-vision users.

**Requirements:**

| Text Type | Minimum Contrast | Recommended |
|-----------|-----------------|-------------|
| **Normal text** (< 18pt) | 4.5:1 | 7:1 |
| **Large text** (18pt+) | 3:1 | 4.5:1 |
| **UI components** | 3:1 | 4.5:1 |

**Checking contrast:**
- Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Ensure text on colored backgrounds meets ratio

**Our color palette:**

| Element | Foreground | Background | Contrast | WCAG |
|---------|-----------|------------|----------|------|
| Body text | #1a1a1a | #ffffff | 15.3:1 | ✅ AAA |
| Code block | #1a1a1a | #f5f5f5 | 12.6:1 | ✅ AAA |
| Emphasis | #1a1a1a | #fff4e1 | 12.1:1 | ✅ AAA |

---

### 5. Code Block Accessibility

**Purpose:** Make code readable for screen readers.

**Guidelines:**

**✅ GOOD - Language specified:**
```markdown
```swift
actor HealthKitService {
    // code here
}
```

```bash
healthsync discover
```

**❌ BAD - No language:**
```
actor HealthKitService {
    // code here
}
```

**For inline code:**
```markdown
Use the `async` keyword to mark functions.
```

---

### 6. Table Accessibility

**Purpose:** Make tables navigable for screen readers.

**Guidelines:**

**✅ GOOD - Proper headers:**
```markdown
| Component | Purpose | Example |
|-----------|---------|---------|
| `async/await` | Write async code linearly | `await fetchData()` |
```

**For complex tables, add scope:**
```markdown
| Heading 1 | Heading 2 |
|-----------|-----------|
| Data 1 | Data 2 |

<!-- Note: Markdown tables auto-generate proper HTML with scope -->
```

---

### 7. Keyboard Navigation

**Purpose:** Ensure keyboard-only users can navigate.

**Guidelines:**

**For interactive elements:**
- Ensure all links are keyboard accessible
- Provide skip links for long content
- Use semantic HTML

**Skip link example:**
```html
<a href="#main-content" class="skip-link">Skip to main content</a>
```

---

### 8. Clear Language

**Purpose:** Make content understandable for non-native speakers.

**Guidelines:**

**✅ GOOD - Simple:**
```markdown
Actors prevent data races by allowing only one task to access data at a time.
```

**❌ BAD - Complex:**
```markdown
Actors effectuate data race mitigation strategies through the implementation of serialized access patterns.
```

**Tips:**
- Use active voice
- Avoid jargon when possible
- Define technical terms on first use
- Keep sentences under 25 words
- Use bullet points for complex information

---

## Screen Reader Testing

### Testing with VoiceOver (macOS/iOS)

**Enable VoiceOver:**
- macOS: ⌘F5
- iOS: Settings → Accessibility → VoiceOver

**Navigation:**
- `VO + →` - Next item
- `VO + ←` - Previous item
- `VO + ⇧ + ↓` - Read all
- `VO + U` - Rotor (adjust navigation)

**What to Check:**
1. Can you navigate the page sequentially?
2. Are headings announced correctly?
3. Are links descriptive?
4. Do images have alt text?
5. Are code blocks announced properly?

---

## Accessibility Testing Tools

### Automated Tools

| Tool | Cost | What It Checks |
|------|------|----------------|
| [axe DevTools](https://www.deque.com/axe/devtools/) | Free | WCAG issues |
| [WAVE](https://wave.webaim.org/) | Free | Contrast, alt text, more |
| [Lighthouse](https://developers.google.com/web/tools/lighthouse/) | Free | Performance, a11y, SEO |
| [pa11y](https://github.com/pa11y/pa11y) | Free | HTML accessibility |

### Running Automated Checks

```bash
# Using pa11y (CLI tool)
npm install -g pa11y

# Check a page
pa11y https://your-docs-url.com/page

# Check all pages
find . -name "*.md" -exec pa11y {} \;
```

---

## Accessibility Statements

### Per-Page Statement

**Include at bottom of each page:**

```markdown
---
## Accessibility

This document aims to meet WCAG 2.1 AA standards. If you encounter accessibility barriers, please [report them](https://github.com/mneves75/ai-health-sync-ios/issues/new?template=accessibility).

**Last accessibility review:** 2026-01-07
**Conformance:** WCAG 2.1 Level AA
---
```

---

## Common Accessibility Issues & Fixes

### Issue: Missing Alt Text

**Problem:**
```markdown
![diagram](images/arch.png)
```

**Fix:**
```markdown
![Architecture diagram showing 4 layers](images/arch.png)
```

---

### Issue: Poor Heading Structure

**Problem:**
```markdown
## Section 1
##### Subsection  <!-- Skipped levels -->
```

**Fix:**
```markdown
## Section 1
### Subsection  <!-- Proper hierarchy -->
```

---

### Issue: Low Contrast

**Problem:**
```markdown
<span style="color: #ccc">Light gray text</span>
```

**Fix:**
```markdown
<span style="color: #666">Darker gray text (better contrast)</span>
```

---

### Issue: Vague Links

**Problem:**
```markdown
Click [here](link) for more info.
```

**Fix:**
```markdown
Learn more in the [troubleshooting guide](link).
```

---

## Creating Accessible Content

### Before Publishing

**Checklist:**

1. **Run automated tests:**
   ```bash
   pa11y https://your-docs-url.com
   ```

2. **Test with screen reader:**
   - Enable VoiceOver
   - Navigate page
   - Verify all content is accessible

3. **Check keyboard navigation:**
   - Tab through links
   - Verify all interactive elements work

4. **Validate contrast:**
   - Use contrast checker
   - Ensure 4.5:1 minimum ratio

5. **Proofread for clarity:**
   - Simple language
   - No jargon without definition
   - Short sentences

---

## Accessibility Resources

### Learning Resources

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Accessibility Tutorials](https://webaim.org/tutorials/)
- [A11Y Project Checklist](https://www.a11yproject.com/checklist/)
- [Accessibility Style Guide](https://accessibilitystyleguide.com/)

### Testing Resources

- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker.html)

### Community

- [A11Y Discord](https://discord.gg/a11y)
- [WebAIM Forums](https://webaim.org/discussion/)
- [Accessibility Slack](https://a11y-slack.herokuapp.com/)

---

## Reporting Accessibility Issues

**Found an accessibility barrier?**

Please report it:
- **GitHub Issues:** [Create accessibility issue](https://github.com/mneves75/ai-health-sync-ios/issues/new?template=accessibility.md)

**When reporting, please include:**
- The page URL
- The accessibility barrier encountered
- Assistive technology used (screen reader, magnifier, etc.)
- Expected behavior

---

## Accessibility Commitment

**We pledge to:**

✅ Maintain WCAG 2.1 AA compliance
✅ Test with screen readers regularly
✅ Fix accessibility issues within 30 days
✅ Invite feedback from disabled users
✅ Provide alternative formats on request
✅ Train contributors on accessibility

**Accessibility contact:** [GitHub Issues](https://github.com/mneves75/ai-health-sync-ios/issues)

---

## See Also

- [Writing Guide](./contributing/documentation.md) - Documentation standards
- [Success Metrics](./METRICS.md) - Measuring documentation quality
- [Contributing Guide](../CONTRIBUTING.md) - How to contribute

---

**Accessibility Guide Version:** 1.0.0
**Last Updated:** 2026-01-07
**Next Review:** 2026-04-07
**WCAG Version:** 2.1 AA
