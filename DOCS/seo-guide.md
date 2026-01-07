# Search Optimization Guide

**Making documentation discoverable and searchable**

---

## Overview

This guide explains how to optimize documentation for search engines (SEO) and on-site search, helping users find the information they need quickly.

**Goals:**
- ✅ Users find answers in < 2 seconds
- ✅ Search success rate > 80%
- ✅ Zero-result searches < 10%
- ✅ High Google rankings for key terms

---

## Table of Contents

1. [Keyword Research](#keyword-research)
2. [On-Page SEO](#on-page-seo)
3. [Content Structure](#content-structure)
4. [Technical SEO](#technical-seo)
5. [Site Search Optimization](#site-search-optimization)
6. [Measuring Success](#measuring-success)

---

## Keyword Research

### Identify User Search Intent

**What are users searching for?**

| User Intent | Example Queries | Target Content |
|-------------|-----------------|----------------|
| **Get Started** | "how to install", "quick start", "setup guide" | QUICKSTART.md |
| **Fix Problems** | "not working", "error message", "can't connect" | TROUBLESHOOTING.md |
| **Learn** | "how does it work", "architecture", "tutorial" | Learning guide |
| **Reference** | "API docs", "function reference", "parameters" | Reference docs |
| **Compare** | "vs alternative", "better than", "differences" | Explanations |

### Keyword Brainstorming

**For the iOS Health Sync app:**

**Primary Keywords:**
- iOS Health Sync
- HealthKit data sync
- iPhone health data to Mac
- Local health sync
- Secure health data transfer

**Long-tail Keywords:**
- "how to sync health data from iPhone to Mac"
- "iOS HealthKit tutorial"
- "Swift 6 HealthKit example"
- "mTLS pairing iOS"
- "HealthKit to CSV export"

**Technical Keywords:**
- Swift 6 concurrency
- SwiftUI @Observation
- Actor isolation
- Network framework TLS
- HealthKit authorization

### Tools for Keyword Research

- **Google Trends** - See what's trending
- **Google Search Console** - See what people search to find your docs
- **GitHub search logs** - If using GitHub search
- **Site search analytics** - See what users search for on your site

---

## On-Page SEO

### Title Tags

**Best Practices:**
- Include primary keyword
- Keep under 60 characters
- Make it descriptive and compelling

**Examples:**

✅ **Good:**
```markdown
# iOS Health Sync: Secure HealthKit Data Sync from iPhone to Mac
```

❌ **Bad:**
```markdown
# Documentation
```

### Meta Descriptions

**Add front matter to key pages:**

```yaml
---
title: "Quick Start Guide - iOS Health Sync"
description: "Get iOS Health Sync running in 10 minutes. Learn how to install, pair devices, and fetch health data from your iPhone to Mac securely."
keywords: [iOS, HealthKit, sync, tutorial, quick start]
author: "Your Name"
date: 2026-01-07
---
```

**Best Practices:**
- 150-160 characters
- Include primary keyword
- Include a call-to-action
- Make it compelling

### Heading Structure

**Use proper hierarchy:**

```markdown
# Main Title (H1) - One per page

## Section (H2) - Main topics

### Subsection (H3) - Details

#### Detail (H4) - Rarely needed
```

**Include keywords in headings:**

✅ **Good:**
```markdown
## How to Pair iOS and Mac Devices
### Troubleshooting Pairing Issues
```

❌ **Bad:**
```markdown
## Setup
### Issues
```

### Content Optimization

**Keyword Placement:**

1. **Title** - Include primary keyword
2. **First paragraph** - Mention what the page covers
3. **Headings** - Use keyword variations
4. **Body** - Use natural language, don't keyword stuff
5. **Alt text** - Describe images with keywords where relevant

**Example (QUICKSTART.md):**

```markdown
# Quick Start: Install iOS Health Sync in 10 Minutes

This guide shows you how to set up **iOS Health Sync** on your Mac and iPhone.
You'll learn to install the app, pair devices, and fetch **HealthKit data** securely.

## What You'll Need

Before installing **iOS Health Sync**, make sure you have...
```

---

## Content Structure

### Use Diataxis Framework

**Content type determines structure:**

| Type | Purpose | SEO Strategy |
|------|---------|--------------|
| **Tutorials** | Learning | "How to", "Tutorial for" keywords |
| **How-To** | Problem-solving | "Fix", "Solve", "Error" keywords |
| **Reference** | Look up | Function names, API keywords |
| **Explanation** | Understanding | "How it works", "Why" keywords |

### Create Topic Clusters

**Hub page + related content:**

```
Hub: learn/00-welcome.md (Learning Guide)
├── learn/01-overview.md (What the app does)
├── learn/02-architecture.md (System design)
├── learn/03-swift6.md (Swift 6 concepts)
├── learn/04-swiftui.md (SwiftUI patterns)
└── learn/06-healthkit.md (HealthKit integration)

Internal links between all pages
```

**SEO Benefits:**
- Establishes topical authority
- Keeps users on site longer
- Internal links boost SEO

### Link Structure

**Internal Links:**

✅ **Descriptive anchor text:**
```markdown
See the [pairing troubleshooting guide](how-to/troubleshoot-pairing.md) for help.
```

❌ **Vague anchor text:**
```markdown
Click [here](how-to/troubleshoot-pairing.md) for help.
```

**External Links:**

- Link to official Apple documentation (HealthKit, SwiftUI)
- Link to related projects
- Link to relevant blog posts
- Use `rel="noopener noreferrer"` for security

---

## Technical SEO

### URL Structure

**Best Practices:**
- Use hyphens, not underscores
- Keep URLs short and descriptive
- Use lowercase letters
- Include keywords

**Examples:**

✅ **Good:**
```
/learn/quick-start.html
/how-to/pair-devices.html
/reference/healthkit-api.html
```

❌ **Bad:**
```
/learn/docs/Quick_Start_Guide_v2.html
/page123.html
/docs.php?id=45
```

### Sitemap

**Create sitemap.xml:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://your-docs-url.com/</loc>
    <lastmod>2026-01-07</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://your-docs-url.com/quick-start</loc>
    <lastmod>2026-01-07</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
  <!-- Add more URLs -->
</urlset>
```

**Submit to:**
- Google Search Console
- Bing Webmaster Tools

### Robots.txt

**Allow search engines:**

```txt
User-agent: *
Allow: /

# Disallow search/results pages
Disallow: /search?

# Sitemap location
Sitemap: https://your-docs-url.com/sitemap.xml
```

### Page Speed

**Optimize for fast loading:**
- Compress images (WebP format)
- Minify CSS/JS
- Use CDN for static assets
- Lazy load images
- Enable compression (gzip/brotli)

**Measure with:** Google PageSpeed Insights, Lighthouse

---

## Site Search Optimization

### Search Implementation

**Options:**

| Solution | Cost | Pros | Cons |
|----------|------|------|------|
| **Algolia** | Free tier | Fast, typo-tolerant | Rate limits on free |
| **GitHub Search** | Free | Good for repos | Limited customization |
| **Lunr.js** | Free | Client-side, no server | Large index file |
| **Elasticsearch** | Self-hosted | Powerful, scalable | Complex setup |

### Search Analytics

**Track what users search for:**

```javascript
// Track search events
function trackSearch(query, resultsCount) {
  gtag('event', 'search', {
    'search_term': query,
    'results_count': resultsCount
  });
}
```

**Review monthly:**
- Top searches
- Zero-result searches
- Search click-through rate
- Searches per session

### Optimize for Zero-Result Searches

**If users search "pairing" and get no results:**

1. **Create content** for that topic
2. **Add synonyms** to search index ("device pairing", "connect devices")
3. **Add redirects** to relevant content
4. **Improve content** with those keywords

**Create a "Did you mean?" feature:**

```javascript
const suggestions = {
  'pariing': 'pairing',
  'sync': 'fetch',
  'connect': 'pair',
  'data': 'health data'
};
```

---

## Measuring Success

### Key Metrics

| Metric | How to Measure | Target |
|--------|----------------|--------|
| **Search CTR** | Google Search Console | > 30% |
| **Average Position** | Google Search Console | Top 10 |
| **Organic Traffic** | Analytics | Increasing |
| **Time on Page** | Analytics | > 3 minutes |
| **Bounce Rate** | Analytics | < 50% |
| **Internal Search Rate** | Site search analytics | < 20% (most find via nav) |
| **Search Success Rate** | Site search analytics | > 80% |

### Google Search Console

**Set up:**

1. Verify site ownership
2. Submit sitemap
3. Monitor performance
4. Fix errors

**Key Reports:**
- **Performance** - See what searches bring traffic
- **Coverage** - Find indexing issues
- **Enhancements** - Mobile usability, structured data

### Analytics Tracking

**Track documentation usage:**

```javascript
// Page view tracking
gtag('event', 'page_view', {
  'page_title': document.title,
  'page_location': window.location.href
});

// Search tracking
gtag('event', 'search', {
  'search_term': searchQuery
});

// Feedback tracking
gtag('event', 'feedback', {
  'page_location': window.location.href,
  'feedback_type': 'helpful'
});
```

---

## Content Promotion

### Internal Discovery

**Link from high-traffic pages:**

- README.md → Quick Start
- Quick Start → Troubleshooting
- All pages → Learning Guide

### External Promotion

**Share on:**
- GitHub Discussions
- Stack Overflow (answer questions with links)
- Reddit (r/Swift, r/iOSProgramming)
- Twitter/X (share tips)
- Hacker News (launch posts)

**Create backlinks:**
- Guest posts on tech blogs
- Open source directories
- App directories

### Community Engagement

**Answer questions on:**
- GitHub Issues
- Stack Overflow
- Reddit
- Discord/Slack communities

**Include links to documentation** in answers.

---

## Continuous Improvement

### Monthly SEO Tasks

1. **Review Search Console** - Check for new keywords, drops in rankings
2. **Check Analytics** - Identify high-exit pages to improve
3. **Review Search Logs** - Find zero-result searches
4. **Update Old Content** - Keep it fresh and accurate
5. **Build Internal Links** - Connect related content

### Quarterly SEO Audit

1. **Keyword Research** - Identify new opportunities
2. **Competitor Analysis** - See what ranks for your keywords
3. **Content Gap Analysis** - Find topics you're missing
4. **Technical Audit** - Check for broken links, slow pages
5. **Backlink Review** - See who's linking to you

### SEO Checklist

**Every new page:**
- [ ] Keyword in title
- [ ] Keyword in first paragraph
- [ ] Proper heading structure (H1 → H2 → H3)
- [ ] Internal links to/from related content
- [ ] Descriptive anchor text
- [ ] Alt text for images
- [ ] Meta description
- [ ] URL is short and descriptive
- [ ] Added to sitemap

---

## SEO Tools

### Free Tools

- **Google Search Console** - Performance, errors
- **Google Analytics** - Traffic, user behavior
- **Google PageSpeed Insights** - Speed optimization
- **Google Keyword Planner** - Keyword research
- **Schema.org Validator** - Structured data

### Paid Tools

- **Ahrefs** - Backlinks, keywords, competitors
- **SEMrush** - Keyword research, site audits
- **Moz Pro** - SEO suite
- **Screaming Frog** - Site crawling

---

## Related Documentation

- **[Accessibility Guide](./ACCESSIBILITY.md)** - WCAG compliance helps SEO
- **[Metrics Guide](./METRICS.md)** - Measuring documentation success
- **[Writing Guide](./contributing/documentation.md)** - Content standards

---

## Quick Reference

### SEO Best Practices Checklist

**On-Page:**
- [ ] Descriptive title with keyword
- [ ] Compelling meta description
- [ ] Proper heading hierarchy
- [ ] Keywords naturally in content
- [ ] Internal links
- [ ] Alt text for images

**Technical:**
- [ ] Clean URL structure
- [ ] Sitemap submitted
- [ ] Robots.txt configured
- [ ] Fast page load speed
- [ ] Mobile-friendly
- [ ] HTTPS enabled

**Content:**
- [ ] Answers user questions
- [ ] Easy to scan (headings, lists)
- [ ] Updated regularly
- [ ] Links to authoritative sources
- [ ] Unique, original content

---

**SEO Guide Version:** 1.0.0
**Last Updated:** 2026-01-07
**Next Review:** 2026-04-07

---

**Remember:** Good SEO = Good User Experience
Focus on helping users find what they need quickly, and rankings will follow.
