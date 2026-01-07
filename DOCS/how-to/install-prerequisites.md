# Install Prerequisites: Set Up Your Development Environment

**Get your Mac ready for iOS Health Sync development**

---

**Time:** 15 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Mac with macOS 15 Sequoia or later
- [ ] Admin access to install software
- [ ] Apple ID (for Xcode)

---

## Goal

Install all required tools and dependencies to build and run iOS Health Sync on your development machine.

---

## Steps

### Step 1: Install Xcode 26

1. Open the **App Store** on your Mac
2. Search for **"Xcode"**
3. Click **"Get"** or **"Update"** to install Xcode 26
4. Wait for download to complete (approximately 12 GB)

**Alternative: Command Line**
```bash
# If you have mas (Mac App Store CLI) installed
mas install 497799835
```

**Verification:**
```bash
xcodebuild -version
# Should output: Xcode 26.x
```

---

### Step 2: Install Command Line Tools

1. Open **Terminal**
2. Run the following command:

```bash
xcode-select --install
```

3. Click **"Install"** in the dialog that appears
4. Wait for installation to complete

**Verification:**
```bash
swift --version
# Should output: swift-driver version 6.x.x Apple Swift version 6.x
```

---

### Step 3: Accept Xcode License

```bash
sudo xcodebuild -license accept
```

Enter your admin password when prompted.

---

### Step 4: Verify Swift Version

```bash
swift --version
```

**Expected output:**
```
swift-driver version 6.0.0 Apple Swift version 6.0 (swiftlang-...)
Target: arm64-apple-macosx15.0
```

**Important:** Swift 6.0+ is required for this project.

---

### Step 5: Clone the Repository

```bash
# Navigate to your development directory
cd ~/dev

# Clone the repository
git clone https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
```

---

### Step 6: Open the Project

```bash
# Open iOS app in Xcode
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

Or double-click the `.xcodeproj` file in Finder.

---

### Step 7: Build the macOS CLI

```bash
# Navigate to CLI directory
cd macOS/HealthSyncCLI

# Build the CLI
swift build

# Verify it built successfully
.build/debug/healthsync --help
```

---

## Verification

**Check all prerequisites are installed:**

```bash
# Create a verification script
echo "Checking prerequisites..."
echo "Xcode: $(xcodebuild -version | head -1)"
echo "Swift: $(swift --version | head -1)"
echo "Git: $(git --version)"
```

**Expected output:**
```
Checking prerequisites...
Xcode: Xcode 26.0
Swift: swift-driver version 6.0.0 Apple Swift version 6.0
Git: git version 2.x.x
```

---

## Common Issues

### Issue: "Xcode not found"

**Cause:** Xcode not installed or path not set.

**Solution:**
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Issue: "Swift version too old"

**Cause:** Using older Xcode or command line tools.

**Solution:**
1. Update Xcode to version 26 from App Store
2. Run: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

### Issue: "Cannot install on Intel Mac"

**Cause:** This app requires Apple Silicon (M1/M2/M3/M4).

**Solution:**
- Use a Mac with Apple Silicon processor
- Run in Rosetta (limited functionality): `arch -x86_64 swift build`

---

## Optional Tools

### Homebrew (Package Manager)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### SwiftLint (Code Linting)

```bash
brew install swiftlint
```

### Simulator (for testing)

Simulators are included with Xcode. To download additional simulators:
1. Open Xcode
2. Go to **Xcode > Settings > Platforms**
3. Download iOS 26 Simulator

---

## See Also

- [Quick Start Guide](../QUICKSTART.md) - Get running in 10 minutes
- [Configure HealthKit](./configure-healthkit.md) - Enable health data access
- [Troubleshooting Build Errors](./fix-build-errors.md) - Common build issues

---

**Last Updated:** 2026-01-07
