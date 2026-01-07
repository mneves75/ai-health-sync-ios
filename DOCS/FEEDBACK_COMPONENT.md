# Feedback Component

**Include this component in every documentation page**

---

## HTML Component

**⚠️ IMPORTANT: This requires a backend to collect feedback.**

The HTML/JavaScript component below provides an in-page feedback form, but it needs:
1. A backend endpoint to receive feedback data
2. A database or service to store feedback
3. Analytics integration (optional but recommended)

**For GitHub-hosted documentation without a backend, use the Markdown Component instead.**

```html
<!-- Only use this if you have a feedback backend -->
<div class="doc-feedback">
  <h3>Was this page helpful?</h3>

  <div class="feedback-buttons">
    <button
      class="feedback-btn"
      data-feedback="helpful"
      aria-label="This page was helpful"
      onclick="handleFeedback('helpful')">
      <span aria-hidden="true">👍</span> Yes
    </button>

    <button
      class="feedback-btn"
      data-feedback="not-helpful"
      aria-label="This page was not helpful"
      onclick="handleFeedback('not-helpful')">
      <span aria-hidden="true">👎</span> No
    </button>
  </div>

  <!-- REST OF HTML COMPONENT HERE - SEE FULL FILE -->
</div>
```

**To implement feedback collection, you have several options:**

1. **GitHub Issues (Recommended for open source)** - Use the Markdown component above
2. **Third-party services** - Disqus, Utterances, giscus (all need setup)
3. **Custom backend** - Requires API endpoint + database
4. **Analytics only** - Track feedback events in GA/Plausible but don't store comments

**Recommendation:** Start with the Markdown GitHub Issues approach. It's simple, requires no infrastructure, and keeps feedback in the same place as code.

---

## Markdown Component (for Static Sites)

**This is the RECOMMENDED approach for GitHub-hosted documentation.**

```markdown
---
## 💡 Feedback

**Was this page helpful?**

Your feedback helps improve this documentation for everyone.

### Quick Feedback

- 👍 **Page was helpful** → [Tell us what worked](https://github.com/mneves75/ai-health-sync-ios/issues/new?title=%5BDOC%5D+Positive+Feedback&labels=documentation,feedback&body=###+What+was+helpful%3F%0D%0A%0D%0A<!--+Please+describe+what+you+liked+about+this+page+-->)
- 👎 **Page needs work** → [Tell us what to fix](https://github.com/mneves75/ai-health-sync-ios/issues/new?title=%5BDOC%5D+Feedback+Needed&labels=documentation,feedback&body=###+What+needs+improvement%3F%0D%0A%0D%0A<!--+Please+describe+what+was+confusing+or+missing+-->)
- ✏️ **Improve this page** → [Edit on GitHub](https://github.com/mneves75/ai-health-sync-ios/edit/main/DOCS/PAGE_NAME.md)

### Report Issues

- 🐛 **Found a bug or error?** → [Open an issue](https://github.com/mneves75/ai-health-sync-ios/issues/new?template=documentation-feedback.md&title=[DOC]+Issue+in+PAGE_NAME)
- 💡 **Suggest an improvement** → [Request a feature](https://github.com/mneves75/ai-health-sync-ios/issues/new?template=feature_request.md)
- ❓ **Have a question?** → [Ask on Discussions](https://github.com/mneves75/ai-health-sync-ios/discussions)

### How to Edit

1. Click the "Edit on GitHub" link above
2. Make your changes
3. Submit a pull request
4. We'll review and merge promptly!

**For immediate help:**
- Check our [Troubleshooting Guide](./TROUBLESHOOTING.md)
- Search our [Documentation Index](./README.md)
- Join our community discussions

---
```

---

## GitHub Issue Templates

### Positive Feedback Template

**File:** `.github/ISSUE_TEMPLATE/positive-feedback.md`

```markdown
---
name: Positive Feedback
about: Share what you liked about the documentation
title: '[DOC] Positive Feedback: '
labels: documentation, feedback
---

## What You Liked

Which page or section was helpful?

- [ ] Quick Start
- [ ] Tutorials
- [ ] How-To Guides
- [ ] Reference
- [ ] Explanation
- [ ] Other: _________

## What Worked Well

What specifically helped you?

**Examples:**
- Clear step-by-step instructions
- Good code examples
- Helpful diagrams
- Easy to find information
- Right level of detail

## Suggestions

Is there anything we could do even better?

---

Thank you for taking the time to share positive feedback! 🎉
```

### Documentation Feedback Template

**File:** `.github/ISSUE_TEMPLATE/documentation-feedback.md`

```markdown
---
name: Documentation Feedback
about: Report a problem or suggest improvements to the documentation
title: '[DOC] Feedback: '
labels: documentation, feedback
---

## Page URL

Which page are you providing feedback on?

https://your-docs-url.com/path/to/page

## Type of Feedback

- [ ] Missing information
- [ ] Unclear or confusing
- [ ] Inaccurate information
- [ ] Broken link
- [ ] Code example doesn't work
- [ ] Accessibility issue
- [ ] Other: _________

## Details

What was missing, confusing, or inaccurate?

**Please describe:**
[Your detailed feedback here]

## Expected Behavior

What did you expect to find or happen?

## Screenshots (if applicable)

<!-- Drag and drop screenshots here -->

## Environment

- **Browser/OS:** _____________
- **Assistive technology:** _____________ (if applicable)

---

Thank you for helping us improve our documentation! 🙏
```

---

## Alternative: Text-Only Feedback

**For minimal setups:**

```markdown
---
## Feedback

**Was this helpful?**

- 👍 Yes: [Like](https://github.com/your-org/repo/stargazers)
- 👎 No: [Report issue](https://github.com/your-org/repo/issues/new)
- ✏️ Edit: [Improve page](https://github.com/your-org/repo/edit/main/docs/page.md)

**Quick links:**
- 📚 [All documentation](../)
- 🔍 [Search docs](../search/)
- 💬 [Get help](https://discord.gg/your-server)
---
```

---

## Integration Instructions

### For Static Site Generators

**Hugo/Jekyll/MkDocs:**

Create a partial: `layouts/partials/feedback.html`

Include in your template:
```html
{{ partial "feedback.html" . }}
```

### For Docusaurus

Create a component: `src/components/Feedback.js`

Use in MDX:
```jsx
import Feedback from '@site/src/components/Feedback';

# Page Content

<Feedback />
```

### For Pure Markdown

Include at bottom of each page:
```markdown
---

{% include "feedback-component.md" %}
```

---

## Tracking Feedback

### GitHub Analytics

```javascript
// Track feedback events
function trackFeedback(type, page, comments) {
  // Send to GitHub Issues via API
  fetch('https://api.github.com/repos/your-org/repo/issues', {
    method: 'POST',
    headers: {
      'Authorization': 'token YOUR_GITHUB_TOKEN',
      'Accept': 'application/vnd.github.v3+json'
    },
    body: JSON.stringify({
      title: `Doc Feedback: ${page}`,
      body: `Type: ${type}\nComments: ${comments}`,
      labels: ['documentation', 'feedback']
    })
  });
}
```

### Google Analytics

```javascript
// Track feedback events
gtag('event', 'doc_feedback', {
  'page_title': document.title,
  'page_location': window.location.href,
  'feedback_type': type,
  'has_comments': comments.length > 0
});
```

---

## Feedback Response Template

**When responding to feedback:**

```markdown
Thank you for your feedback! We've made the following improvements:

## Changes Made

- [x] Added missing information about X
- [x] Clarified section Y
- [x] Fixed broken link to Z
- [x] Improved accessibility of W

## Your Feedback Impact

You helped us improve the documentation by:
- [Specific improvement]
- [Another improvement]

We'd love to hear from you again after we make these changes!

---

**Response from:** @maintainer
**Date:** 2026-01-07
**Related Issue:** #123
```

---

## Feedback Best Practices

### Respond Quickly

- **Aim for:** Response within 24-48 hours
- **Even if:** Just to acknowledge receipt

### Be Appreciative

- **Thank users** for taking time to provide feedback
- **Credit them** in changelog if they make suggestions

### Close the Loop

- **Notify users** when issues are fixed
- **Link to:** Related PR or commit

### Learn from Patterns

- **Track common issues** to identify content gaps
- **Use feedback** to prioritize improvements

---

## See Also

- [Accessibility Guide](../ACCESSIBILITY.md) - Inclusive documentation
- [Contributing Guide](../CONTRIBUTING.md) - How to improve docs
- [Metrics Guide](../METRICS.md) - Measuring success

---

**Feedback Component Version:** 1.0.0
**Last Updated:** 2026-01-07
