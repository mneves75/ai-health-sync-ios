# Video Transcript: Quick Start Guide (10 minutes)

**Video Title:** Get iOS Health Sync Running in 10 Minutes
**Duration:** 10:00
**Difficulty:** Beginner
**Related Docs:** [Quick Start Guide](../QUICKSTART.md)

---

## Transcript

### [0:00] Introduction

**[Visual: Title slide with project logo and "Quick Start" text]**

**Speaker:** "Hi, I'm [Name], and in this video I'll show you how to get the iOS Health Sync app running on your Mac in just 10 minutes. We'll cover everything from cloning the repository to fetching your first health data."

**[Visual: Screen recording showing completed app with health data displayed]**

**Speaker:** "By the end of this video, you'll have a fully functional iOS health sync system running locally on your own devices. Let's get started!"

---

### [0:30] Prerequisites

**[Visual: Checklist of requirements appearing one by one]**

**Speaker:** "Before we begin, make sure you have:"

**[Visual: Mac with macOS 15 Sequoia logo]**

**Speaker:** "A Mac running macOS 15 Sequoia or later. This is required for the latest Swift 6 and Xcode 26 features."

**[Visual: Xcode icon]**

**Speaker:** "Xcode 26 or later installed. You can get this free from the Mac App Store."

**[Visual: iOS Simulator or iPhone]**

**Speaker:** "Either an iOS 26 Simulator or a physical iPhone or iPad for testing the app."

**[Visual: Swift logo]**

**Speaker:** "And Swift 6 which comes with Xcode. The CLI tool is built as a Swift Package."

**[Visual: All items checked off]**

**Speaker:** "That's it! Let's dive in."

---

### [1:30] Step 1: Clone the Repository

**[Visual: Terminal window, typing command]**

**Speaker:** "First, open your Terminal and clone the repository:"

```bash
git clone https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
```

**[Visual: File appearing in Finder showing the project directory]**

**Speaker:** "This downloads all the project files to your Mac. You'll see two main folders: the iOS app and the macOS CLI tool."

---

### [2:30] Step 2: Open the iOS Project

**[Visual: Double-clicking the Xcode project file]**

**Speaker:** "Now let's open the iOS app in Xcode. Navigate to the 'iOS Health Sync App' folder and double-click the Xcode project file."

**[Visual: Xcode opening, showing project structure]**

**Speaker:** "Xcode will open and load the project. You'll see the project structure on the left, with folders for App, Core, Features, and Services."

**[Visual: Highlighting the target selector]**

**Speaker:** "Make sure the target is set to 'iPhone 16 Simulator' or any iOS 26 simulator you have installed."

---

### [3:30] Step 3: Build and Run the iOS App

**[Visual: Pressing ⌘R or clicking the Run button]**

**Speaker:** "Now press Command-R or click the Run button in the top-left corner."

**[Visual: Build progress indicator]**

**Speaker:** "Xcode will build the app. This might take a minute or two on the first build as it compiles all the Swift code."

**[Visual: iOS Simulator appearing with the app running]**

**Speaker:** "Once the build completes, the iOS Simulator will launch and you'll see the iOS Health Sync app. You'll see options for selecting health data types and buttons to start the server."

**[Visual: Toggling health data types in the app]**

**Speaker:** "Go ahead and toggle the health data types you want to sync - like Steps, Heart Rate, and Sleep."

---

### [5:00] Step 4: Start the Server

**[Visual: Tapping "Start Sharing" button]**

**Speaker:** "Now tap the 'Start Sharing' button to start the local TLS server."

**[Visual: Server status changing to "Running", QR code appears]**

**Speaker:** "The server status will update to show that it's running, and the QR code appears automatically. This contains the server URL and certificate fingerprint needed for secure pairing."

**[Visual: QR code displayed with pairing code and expiration]**

**Speaker:** "The QR code includes a pairing code and expiration time. You can tap 'Refresh Code' to generate a new one if needed."

---

### [6:00] Step 5: Build the CLI Tool

**[Visual: Terminal window, typing commands]**

**Speaker:** "Now let's build the macOS CLI tool. In your Terminal, navigate to the CLI directory:"

```bash
cd macOS/HealthSyncCLI
```

**[Visual: Running swift build]**

**Speaker:** "Build the CLI using Swift Package Manager:"

```bash
swift build
```

**[Visual: Build output showing successful compilation]**

**Speaker:** "Swift will compile the CLI tool. You'll see the compiled binary in the .build/debug directory."

---

### [7:00] Step 6: Pair Devices

**[Visual: QR code displayed in iOS app]**

**Speaker:** "Now let's pair your Mac with the iOS app. First, make sure the QR code is visible on the iOS simulator."

**[Visual: In Terminal, running healthsync scan]**

**Speaker:** "In the Terminal, run:"

```bash
.build/debug/healthsync scan
```

**[Visual: Scan successful message]**

**Speaker:** "The CLI will scan the QR code from your clipboard and establish a secure connection using mutual TLS authentication."

**[Visual: Running healthsync status]**

**Speaker:** "Verify the pairing by checking the connection status:"

```bash
.build/debug/healthsync status
```

---

### [8:00] Step 7: Fetch Health Data

**[Visual: Running fetch command]**

**Speaker:** "Now let's fetch some health data. Run:"

```bash
.build/debug/healthsync fetch --types steps --start 2026-01-01
```

**[Visual: Health data output in CSV format]**

**Speaker:** "The CLI will fetch your steps data from the iOS app and display it in CSV format. You can redirect this to a file:"

```bash
.build/debug/healthsync fetch --types steps --start 2026-01-01 > steps.csv
```

**[Visual: CSV file opening in spreadsheet app]**

**Speaker:** "Open the CSV file in any spreadsheet application to view your health data."

---

### [9:00] Next Steps

**[Visual: Documentation browser showing various guides]**

**Speaker:** "Congratulations! You now have a working health sync system. Here are some next steps:"

**[Visual: Quick Start Guide in browser]**

**Speaker:** "Check out the Quick Start Guide for more details on configuration options and troubleshooting."

**[Visual: How-To Guides section]**

**Speaker:** "Explore the How-To Guides for specific tasks like fetching different health data types or customizing the sync interval."

**[Visual: Learning Guide]**

**Speaker:** "And if you want to dive deeper into how the app works, check out the Learning Guide for comprehensive tutorials on Swift 6, SwiftUI, and HealthKit."

---

### [9:45] Summary

**[Visual: Summary checklist]**

**Speaker:** "Let's recap what we covered:"

1. ✅ Cloned the repository
2. ✅ Built and ran the iOS app
3. ✅ Started the local TLS server
4. ✅ Built the CLI tool
5. ✅ Paired devices using QR code
6. ✅ Fetched health data

**[Visual: Thank you slide with links to documentation, GitHub repo]**

**Speaker:** "Thanks for watching! If you run into any issues, check the Troubleshooting guide or open an issue on GitHub. Happy coding!"

**[Visual: Fade to black with project logo]**

**[End of video]**

---

## Additional Resources

- **[Quick Start Guide](../QUICKSTART.md)** - Written version of this video
- **[Troubleshooting Guide](../TROUBLESHOOTING.md)** - Solve common problems
- **[Version Requirements](../VERSIONS.md)** - Compatibility information
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute

---

## Video Metadata

| Property | Value |
|----------|-------|
| **Title** | Quick Start Guide - iOS Health Sync |
| **Duration** | 10:00 |
| **Difficulty** | Beginner |
| **Prerequisites** | macOS 15, Xcode 26, Swift 6 |
| **Related Docs** | QUICKSTART.md |
| **Tags** | setup, installation, getting-started |
| **Language** | English |
| **Subtitles Available** | Yes (English) |
| **Recorded Date** | 2026-01-07 |
| **Last Updated** | 2026-01-07 |

---

## Production Notes

### Visual Style

- Clean, modern interface recordings
- Highlighted UI elements in yellow
- Code in monospace font with syntax highlighting
- Smooth transitions between sections

### Audio Quality

- Clear, professional narration
- Background music at low volume during transitions
- Consistent audio level throughout

### Camera Setup (if applicable)

- Face camera for introduction and conclusion
- Screen recording for all technical steps
- Picture-in-picture for complex workflows

### Accessibility

- Full transcripts provided
- Closed captions available
- Keyboard shortcuts visible when demonstrated
- Color-blind friendly UI highlighting

---

**Transcript Version:** 1.0.0
**Last Updated:** 2026-01-07
