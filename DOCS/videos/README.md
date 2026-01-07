# Video Content Guide

**Video learning resources for the iOS Health Sync project**

---

## Overview

This directory contains video transcripts and production guidance for creating educational videos about the iOS Health Sync app. Videos complement the written documentation by providing visual, step-by-step demonstrations.

---

## Available Videos

### Beginner Level

| Video | Duration | Transcript | Status |
|-------|----------|-----------|--------|
| [Quick Start Guide](transcripts/01-quick-start.md) | 10:00 | ✅ Complete | 🎬 Script Ready |
| [Your First Sync](transcripts/02-first-sync.md) | 12:00 | 📝 Planned | - |
| [Understanding the UI](transcripts/03-ui-overview.md) | 8:00 | 📝 Planned | - |

### Intermediate Level

| Video | Duration | Transcript | Status |
|-------|----------|-----------|--------|
| [Swift 6 Concurrency](transcripts/02-swift6-concurrency.md) | 25:00 | ✅ Complete | 🎬 Script Ready |
| [SwiftUI @Observation](transcripts/04-observation.md) | 18:00 | 📝 Planned | - |
| [HealthKit Integration](transcripts/05-healthkit.md) | 20:00 | 📝 Planned | - |

### Advanced Level

| Video | Duration | Transcript | Status |
|-------|----------|-----------|--------|
| [Architecture Deep Dive](transcripts/10-architecture.md) | 30:00 | 📝 Planned | - |
| [Security & mTLS](transcripts/11-security.md) | 22:00 | 📝 Planned | - |
| [Performance Optimization](transcripts/12-performance.md) | 25:00 | 📝 Planned | - |

---

## Video Production Process

### 1. Script Creation

**Status: 📝 Planned → ✅ Complete**

1. Review related documentation
2. Create detailed transcript with:
   - Timestamp markers every 30 seconds
   - Visual descriptions for each scene
   - Code examples with syntax highlighting
   - Clear transitions between topics
3. Include metadata (duration, difficulty, tags)
4. Add accessibility notes

### 2. Recording

**Status: 🎬 Script Ready → 🎥 Recording**

**Equipment Needed:**
- Microphone (USB or XLR with interface)
- Screen recording software (ScreenFlow, Camtasia, or OBS)
- Optional: Camera for face shots
- Good lighting (if using camera)

**Software Setup:**
- Capture resolution: 1920x1080 (1080p) minimum
- Frame rate: 30 fps
- Audio: 48 kHz, 16-bit minimum
- Use system audio + microphone

**Recording Tips:**
- ✅ Record in a quiet environment
- ✅ Use a microphone (not built-in)
- �. Speak clearly and at moderate pace
- ✅ Practice the script before recording
- ✅ Record in segments (easier to edit)

### 3. Editing

**Status: 🎥 Recording → 🎨 Editing**

**Editing Checklist:**
- [ ] Trim silence and mistakes
- [ ] Add intro/outro music (low volume)
- [ ] Highlight UI elements (yellow box or circle)
- [ ] Add text overlays for key points
- [ ] Insert code examples with syntax highlighting
- [ ] Ensure smooth transitions
- [ ] Check audio levels (consistent throughout)
- [ ] Add chapter markers in timeline

### 4. Accessibility

**Status: 🎨 Editing -> ♿ Accessibility**

**Required:**
- [ ] Full transcript (provided here)
- [ ] Closed captions (.srt file)
- [ ] Audio description (if visual-heavy content)
- [ ] Keyboard shortcuts visible

**Caption Format (.srt):**
```srt
1
00:00:00,000 --> 00:00:05,000
Hi, I'm [Name], and in this video...

2
00:00:05,000 --> 00:00:10,000
I'll show you how to get the iOS Health Sync...
```

### 5. Export & Upload

**Status: ♿ Accessibility → 📤 Published**

**Export Settings:**
- Format: MP4 (H.264)
- Resolution: 1920x1080 (1080p)
- Bitrate: 5-8 Mbps
- Audio: AAC, 192 kbps
- Frame rate: 30 fps

**Upload to:**
- YouTube (primary)
- Vimeo (alternative)
- PeerTube (decentralized option)

**After Upload:**
- Add transcript to video description
- Enable captions
- Add to playlist
- Update documentation links

---

## Creating a New Video

### Template Structure

```markdown
# Video Transcript: [Title]

**Video Title:** [Title]
**Duration:** [MM:SS]
**Difficulty:** [Beginner/Intermediate/Advanced]
**Related Docs:** [Link to documentation]

---

## Transcript

### [0:00] Introduction

**[Visual: Description of visuals]**

**Speaker:** "What the speaker says"

**[Visual: More visuals]**

**Speaker:** "More speech"

---

## Additional Resources

- **[Related Doc 1](path)** - Description
- **[Related Doc 2](path)** - Description

---

## Video Metadata

| Property | Value |
|----------|-------|
| **Title** | [Title] |
| **Duration** | [MM:SS] |
| **Difficulty** | [Level] |
| **Prerequisites** | [Requirements] |
| **Related Docs** | [Link] |
| **Tags** | [tag1, tag2, tag3] |
| **Language** | English |
| **Subtitles Available** | Yes (English) |
| **Recorded Date** | [Date] |
| **Last Updated** | [Date] |

---

**Transcript Version:** 1.0.0
**Last Updated:** [Date]
```

### Naming Convention

```
transcripts/
├── 01-quick-start.md           # Beginner videos (01-09)
├── 02-first-sync.md
├── 03-ui-overview.md
├── ...
├── 10-architecture.md          # Advanced videos (10+)
├── 11-security.md
└── 12-performance.md
```

### Recommended Length

| Audience | Ideal Duration | Max Duration |
|----------|---------------|--------------|
| Beginner | 8-12 minutes | 15 minutes |
| Intermediate | 15-20 minutes | 25 minutes |
| Advanced | 20-30 minutes | 40 minutes |

**Why shorter is better:**
- Higher viewer retention
- Easier to update
- Faster to produce
- Better for learning (chunking)

---

## Video Hosting Options

### YouTube (Recommended)

**Pros:**
- Free hosting
- Excellent accessibility features
- Global CDN
- Integrated captions
- Analytics included

**Cons:**
- Ads (unless you join Partner Program)
- Privacy concerns for some users

### Vimeo

**Pros:**
- No ads
- Professional presentation
- Good privacy controls
- Excellent embedding options

**Cons:**
- Paid plans for full features
- Smaller audience

### PeerTube (Decentralized)

**Pros:**
- Federated, no central authority
- Privacy-focused
- Open source

**Cons:**
- Smaller audience
- Requires self-hosting or finding instance

---

## Embedding Videos in Documentation

### Markdown Format

```markdown
### Video Tutorial

<iframe width="560" height="315"
  src="https://www.youtube.com/embed/VIDEO_ID"
  title="Video title"
  frameborder="0"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>

**[Watch on YouTube](https://youtube.com/watch?v=VIDEO_ID)** | **[Read Transcript](transcripts/video-name.md)**
```

### Accessibility Note

Always provide:
1. Video embed with captions enabled
2. Link to watch on platform (for accessibility features)
3. Link to full transcript (for deaf users and search engines)

---

## Contributing Videos

We welcome community contributions! Here's how:

### For Script Writers

1. Follow the template structure
2. Include detailed visual descriptions
3. Add code examples with syntax highlighting
4. Include timestamps every 30 seconds
5. Submit as PR with "video:" prefix

### For Video Creators

1. Check [Planned Videos](#planned-videos) list
2. Claim a video by opening an issue
3. Follow production process above
4. Submit video link and transcript as PR

### Recording Quality Guidelines

**Minimum Acceptable:**
- 720p resolution
- Clear audio (no echo or background noise)
- Readable text (code examples)
- Smooth screen recordings

**Preferred:**
- 1080p resolution
- Professional microphone
- Edited with highlights
- Multi-camera (screen + face)

---

## Planned Videos

Need to be created (open for contributions):

### High Priority

- [ ] Your First Sync (12 min) - Basic pairing and data fetching
- [ ] Understanding the UI (8 min) - Tour of iOS app interface
- [ ] SwiftUI @Observation (18 min) - Modern state management

### Medium Priority

- [ ] HealthKit Integration (20 min) - Accessing health data
- [ ] Network Architecture (15 min) - TLS server implementation
- [ ] Debugging Tips (12 min) - Common issues and solutions

### Low Priority

- [ ] Architecture Deep Dive (30 min) - System design discussion
- [ ] Security & mTLS (22 min) - Certificate-based pairing
- [ ] Performance Optimization (25 min) - Profiling and improvements

---

## Metrics & Analytics

Track these metrics for each video:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Views** | 100+ in first month | YouTube Analytics |
| **Watch Time** | 50%+ average view duration | YouTube Analytics |
| **Engagement** | 5%+ like ratio | YouTube Analytics |
| **Comments** | 10+ constructive comments | YouTube Analytics |
| **Click-through** | 10%+ from docs | Custom tracking |

**Review quarterly** and update older videos with declining metrics.

---

## Style Guide

### Visual Style

- **Clean, minimalist interface** - Remove desktop clutter
- **Highlight UI elements** - Yellow box or circle around important items
- **Use zoom** - For small UI elements or code
- **Smooth transitions** - Fade or wipe between scenes
- **Consistent branding** - Use project logo and colors

### Audio Style

- **Clear narration** - Speak clearly, moderate pace
- **No background noise** - Record in quiet environment
- **Background music** - Low volume during transitions only
- **Consistent levels** - Normalize audio to -16 LUFS

### On-Screen Text

- **Sans-serif font** - System UI font or similar
- **High contrast** - White text on dark background or vice versa
- **Large enough** - Minimum 24pt for body text
- **Brief** - Keep text short and scannable

---

## Equipment Recommendations

### Beginner (<$100)

- **Microphone:** Blue Yeti USB ($120) or Samson Q2U ($70)
- **Screen Recording:** QuickTime (Mac) or OBS (free, all platforms)
- **Editing:** iMovie (Mac, free) or DaVinci Resolve (free, all platforms)

### Intermediate ($100-$500)

- **Microphone:** Audio-Technica ATR2100x ($80) + boom arm ($30)
- **Camera:** Logitech C920 webcam ($80) - for face shots
- **Lighting:** Neewer ring light ($60)
- **Editing:** ScreenFlow ($130) or Camtasia ($250)

### Professional ($500+)

- **Microphone:** Shure SM7B ($400) + audio interface ($150)
- **Camera:** DSLR or mirrorless camera ($500+)
- **Lighting:** Softbox lights ($200)
- **Editing:** Final Cut Pro ($300) or Adobe Premiere ($240/year)

---

## Related Documentation

- **[Accessibility Guide](../ACCESSIBILITY.md)** - WCAG compliance for videos
- **[Metrics Guide](../METRICS.md)** - Measuring video effectiveness
- **[Contributing Guide](../CONTRIBUTING.md)** - Contribution guidelines

---

## See Also

- **[Learning Guide](../learn/00-welcome.md)** - Comprehensive written tutorials
- **[Code Examples](../../examples/)** - Runnable Swift examples
- **[How-To Guides](../how-to/)** - Step-by-step instructions

---

**Video Guide Version:** 1.0.0
**Last Updated:** 2026-01-07
