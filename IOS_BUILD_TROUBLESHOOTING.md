# iOS Build Troubleshooting - Complete Guide

**Based on Real Issues Encountered During BeatYourRival Development**

This guide documents actual problems we encountered and their solutions, so you can quickly resolve similar issues in the future.

---

## 📋 Table of Contents

1. [CCleaner Deleting Xcode Cache Files](#1-ccleaner-deleting-xcode-cache-files)
2. [SDK Stat Cache File Not Found](#2-sdk-stat-cache-file-not-found)
3. [Corrupted iOS Runner Target](#3-corrupted-ios-runner-target)
4. [Wrong Xcode Project Open](#4-wrong-xcode-project-open)
5. [Xcode Scheme Configuration Issues](#5-xcode-scheme-configuration-issues)
6. [iPhone Not Detected by Flutter](#6-iphone-not-detected-by-flutter)
7. [Module Cache Corruption](#7-module-cache-corruption)
8. [Security Popups (idevicesyslog)](#8-security-popups-idevicesyslog)
9. [Developer Mode Issues](#9-developer-mode-issues)
10. [Quick Reference Commands](#10-quick-reference-commands)

---

## 1. CCleaner Deleting Xcode Cache Files

### **Symptoms**
- ❌ Directories you create immediately disappear
- ❌ `SDKStatCaches.noindex` won't persist
- ❌ Error: "stat cache file not found"
- ❌ Builds fail randomly
- ❌ `mkdir` succeeds but `ls` shows nothing

### **Root Cause**
CCleaner (or similar cleaning utilities) treats Xcode's cache directories as "temporary files" and deletes them during auto-cleaning, even while you're actively building.

### **Solution**

**Option 1: Quit CCleaner (Immediate Fix)**
```bash
killall CCleaner
```

**Option 2: Add Xcode to Exclusions**
1. Open CCleaner app
2. Go to **Settings** → **Exclude** (or Preferences → Ignore)
3. Add these paths:
   ```
   /Users/YOUR_USERNAME/Library/Developer/Xcode/
   /Users/YOUR_USERNAME/Library/Caches/com.apple.dt.Xcode/
   ```
4. Save and restart CCleaner

**Option 3: Uninstall CCleaner (Recommended for Developers)**
```bash
sudo rm -rf /Applications/CCleaner.app
sudo rm -rf ~/Library/Application\ Support/CCleaner
```

### **Verification**
```bash
# Create test directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# Wait 10 seconds
sleep 10

# Check if it still exists
ls -la ~/Library/Developer/Xcode/DerivedData/ | grep SDK

# If you see SDKStatCaches.noindex, CCleaner is no longer interfering ✅
```

### **Why This Happens**
Mac development tools (Xcode, Android Studio, Node.js, CocoaPods) create numerous cache files during builds. Cleaning utilities designed for general Mac maintenance can't distinguish between "safe to delete" and "actively being used" developer caches.

### **Prevention**
- Don't use system cleaning utilities while developing
- If you must use them, exclude all developer directories
- Use built-in cleaning commands instead:
  ```bash
  # Clean Xcode caches manually when needed
  rm -rf ~/Library/Developer/Xcode/DerivedData
  
  # Clean Flutter caches
  flutter clean
  
  # Clean CocoaPods caches
  pod cache clean --all
  ```

---

## 2. SDK Stat Cache File Not Found

### **Symptoms**
- ❌ Error: `stat cache file '/Users/.../SDKStatCaches.noindex/iphoneos18.2-...sdkstatcache' not found`
- ❌ Build fails at Xcode compilation stage
- ❌ Error appears for both physical device and simulator
- ❌ Same error persists across multiple build attempts

### **Root Cause**
Either:
1. CCleaner (or similar tool) deleted the cache file
2. Xcode version mismatch with iOS device version
3. Corrupted Xcode installation
4. Incomplete Xcode Command Line Tools installation

### **Solution**

**Fix 1: Ensure CCleaner is Stopped**
```bash
killall CCleaner
```

**Fix 2: Regenerate Xcode Caches**
```bash
# Remove all Xcode caches
sudo rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Create the SDK stat cache directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# Set proper permissions
chmod 755 ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
```

**Fix 3: Reinstall Xcode Command Line Tools**
```bash
# Remove existing tools
sudo rm -rf /Library/Developer/CommandLineTools

# Reinstall
xcode-select --install

# Click "Install" in the popup that appears

# After installation completes:
sudo xcodebuild -license accept
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Fix 4: Update Xcode (if outdated)**
```bash
# Check current version
xcodebuild -version

# If older than 15.3, update via App Store
# Or download from: https://developer.apple.com/download/

# After updating:
sudo xcodebuild -license accept
```

**Fix 5: Nuclear Option - Complete Xcode Reset**
```bash
# Close Xcode
killall Xcode

# Remove all Xcode caches and derived data
sudo rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport

# Reinstall command line tools
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# Wait for installation to complete, then:
sudo xcodebuild -license accept
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Open Xcode to let it install additional components
open /Applications/Xcode.app
# Close after components install
```

**Fix 6: Build via Flutter CLI (Bypass Xcode)**
```bash
cd /path/to/your/project
flutter clean
flutter pub get
flutter run -d <device-id>
```

### **Verification**
```bash
# Check if SDK cache directory exists and persists
ls -la ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# Try building
flutter run -d 00008110-000E3C281151801E
```

### **Prevention**
- Keep Xcode updated (at least version 15.3 for iOS 18+)
- Don't use cleaning utilities during development
- Don't manually delete Xcode cache files while builds are running

---

## 3. Corrupted iOS Runner Target

### **Symptoms**
- ❌ `pod install` fails: "Unable to find a target named 'Runner'"
- ❌ Xcode shows only "RunnerTests" target, no "Runner" target
- ❌ Can't build iOS app from Xcode or CLI
- ❌ `Runner.xcodeproj` exists but is missing targets

### **Root Cause**
- iOS project structure corrupted (often due to interrupted builds or cache deletion)
- Xcode project file (`Runner.xcodeproj`) missing target definitions
- Incomplete Flutter iOS setup

### **Solution**

**Complete iOS Project Regeneration:**

```bash
# Navigate to project
cd /path/to/your/flutter/project

# Step 1: Backup current iOS folder
cp -r ios ios_backup_$(date +%Y%m%d_%H%M%S)
echo "Backup created"

# Step 2: Save Firebase config (if it exists)
if [ -f ios/Runner/GoogleService-Info.plist ]; then
  cp ios/Runner/GoogleService-Info.plist ~/Desktop/
  echo "Firebase config saved to Desktop"
fi

# Step 3: Remove corrupted iOS files
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Runner.xcodeproj
rm -rf ios/Runner.xcworkspace
echo "Corrupted files removed"

# Step 4: Regenerate iOS project
flutter create --platforms=ios .
echo "iOS project regenerated"

# Step 5: Restore Firebase config
if [ -f ~/Desktop/GoogleService-Info.plist ]; then
  cp ~/Desktop/GoogleService-Info.plist ios/Runner/
  echo "Firebase config restored"
fi

# Step 6: Install dependencies
flutter pub get
echo "Flutter packages installed"

# Step 7: Install pods
cd ios
pod install
cd ..
echo "Pods installed"
```

### **Verification**
```bash
# Check if Runner target exists in Podfile
cat ios/Podfile | grep "target 'Runner'"

# Should see:
# target 'Runner' do
#   use_frameworks!
#   ...
# end

# Verify workspace was created
ls -la ios/Runner.xcworkspace

# Try building
flutter run -d <device-id>
```

### **What Gets Preserved**
- ✅ All Dart code in `lib/`
- ✅ `pubspec.yaml` and dependencies
- ✅ `ios/Runner/Assets.xcassets/` (app icons)
- ✅ `ios/Runner/Info.plist` (iOS config)
- ✅ Firebase config (if backed up)

### **What Gets Recreated**
- ✅ `ios/Runner.xcodeproj` (with proper Runner target)
- ✅ `ios/Podfile` (with correct configuration)
- ✅ `ios/Runner.xcworkspace`
- ✅ iOS build configuration files

### **Prevention**
- Don't interrupt builds (Ctrl+C during compilation)
- Don't manually delete iOS project files
- Use `flutter clean` instead of manual deletion
- Keep backups of working iOS configurations

---

## 4. Wrong Xcode Project Open

### **Symptoms**
- ❌ Bundle ID shows wrong app name (e.g., `com.example.petAi` instead of `com.example.beatrivals_app`)
- ❌ Wrong app name in Xcode navigator
- ❌ Building wrong app entirely
- ❌ Changes don't appear in your app

### **Root Cause**
Multiple Flutter projects exist on Mac, and you opened the wrong one's `Runner.xcworkspace`.

### **Solution**

**Step 1: Find All Flutter Projects**
```bash
# List all Flutter projects
find ~/Documents -name "pubspec.yaml" -maxdepth 5 -exec dirname {} \; 2>/dev/null

# Or more detailed
for dir in $(find ~/Documents -name "pubspec.yaml" -maxdepth 5 -exec dirname {} \; 2>/dev/null); do
  echo "======================================"
  echo "📁 Project: $dir"
  echo "📝 Name: $(grep '^name:' "$dir/pubspec.yaml" | awk '{print $2}')"
  echo ""
done
```

**Step 2: Navigate to Correct Project**
```bash
# Go to your actual project
cd /Users/YOUR_USERNAME/Documents/development/apps/YOUR_APP_NAME

# Verify it's the right one
cat pubspec.yaml | grep name
# Should show the correct app name
```

**Step 3: Close Wrong Xcode, Open Correct One**
```bash
# Close all Xcode windows
killall Xcode

# Wait a moment
sleep 3

# Open correct project
open ios/Runner.xcworkspace
```

**Step 4: Verify in Xcode**
In Xcode, check:
- **Bundle Identifier**: Should match your app
- **Project Navigator**: Should show your app's files
- **Scheme**: Should show correct app name

### **Prevention**
- Use Terminal to navigate to projects: `cd /full/path/to/project`
- Always verify with `cat pubspec.yaml | grep name` before opening Xcode
- Close other Flutter projects' Xcode windows
- Use dedicated workspaces for different projects

---

## 5. Xcode Scheme Configuration Issues

### **Symptoms**
- ❌ Xcode scheme shows "Executable: None"
- ❌ Can't run app from Xcode (Play button doesn't work)
- ❌ Error: "The executable isn't specified"
- ❌ Scheme configuration is missing Runner.app

### **Root Cause**
Xcode scheme lost its executable configuration (often after cleaning caches or regenerating project).

### **Solution**

**Method 1: Use "Ask on Launch" (Easiest)**

1. In Xcode, click **scheme name** (top-left) → **"Edit Scheme..."**
2. Select **"Run"** in left sidebar
3. Under **"Info"** tab → **"Executable"** dropdown
4. Select **"Ask on Launch"**
5. Click **"Close"**
6. Click **Play button (▶️)** to build
7. When prompted, select **"Runner.app"**

**Method 2: Directly Select Runner.app**

1. Edit Scheme → Run → Info
2. Executable dropdown → Click it
3. If "Runner.app" appears, select it
4. If not, click **"Other..."**
5. Navigate to: `~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos/`
6. Select **Runner.app**
7. Click **Choose** → **Close**

**Method 3: Reset Scheme**

```bash
cd /path/to/your/project

# Remove user-specific Xcode data
rm -rf ios/Runner.xcodeproj/xcuserdata
rm -rf ios/Runner.xcworkspace/xcuserdata

# Reopen Xcode
open ios/Runner.xcworkspace
```

Xcode will auto-generate a new scheme with correct settings.

**Method 4: Build via CLI (Bypass Xcode)**

```bash
cd /path/to/your/project
flutter run -d <device-id>
```

This bypasses Xcode's scheme issues entirely.

### **Verification**
In Xcode:
1. Click scheme → "Edit Scheme..."
2. Run → Info → Executable
3. Should show "Runner.app" or "Ask on Launch" ✅

### **Prevention**
- Don't manually delete scheme files
- Use `flutter clean` instead of deleting build folders
- If scheme breaks, use "Ask on Launch" as default

---

## 6. iPhone Not Detected by Flutter

### **Symptoms**
- ❌ `flutter devices` doesn't show iPhone
- ❌ Error: "No supported devices found"
- ❌ Error: "Could not find device" (code -27)
- ❌ Xcode sees iPhone but Flutter doesn't

### **Root Cause**
- iPhone not in Developer Mode
- iPhone not trusted
- iPhone locked during connection
- USB cable issue

### **Solution**

**Step 1: Enable Developer Mode (iOS 16+)**

On iPhone:
1. **Settings** → **Privacy & Security** → **Developer Mode**
2. Toggle **ON**
3. Restart iPhone (when prompted)
4. Confirm "Turn On Developer Mode" after restart

**Step 2: Trust Computer**

1. **Connect iPhone** to Mac via USB
2. **Unlock iPhone**
3. Popup on iPhone: **"Trust This Computer?"**
4. Tap **"Trust"**
5. Enter iPhone passcode

**Step 3: Keep iPhone Unlocked**

- iPhone must be **unlocked** when first connecting
- After successful connection, it can be locked during builds

**Step 4: Verify Connection**

```bash
# Check connected devices
flutter devices

# Should show:
# iPhone (mobile) • DEVICE-ID • ios • iOS 18.x
```

**Step 5: Alternative - Use Device ID**

If device name has issues, use device ID directly:

```bash
# Get device ID
flutter devices

# Use ID instead of name
flutter run -d 00008110-000E3C281151801E
```

### **Troubleshooting**

**Issue: Trust popup doesn't appear**
```bash
# Reset trust settings
sudo rm -rf /var/db/lockdown/*

# Disconnect iPhone, restart Mac, reconnect
```

**Issue: Developer Mode option missing**
- Requires iOS 16 or later
- Update iOS: Settings → General → Software Update

**Issue: "Waiting for connection"**
```bash
# Reset iOS device connection
idevice_id -l

# If not found:
brew install libimobiledevice
idevice_id -l
```

### **Prevention**
- Always enable Developer Mode on development iPhones
- Keep iPhone unlocked during first connection
- Use high-quality USB cables (not cheap knockoffs)
- Update iOS regularly

---

## 7. Module Cache Corruption

### **Symptoms**
- ❌ Error: "Unable to rename temporary file"
- ❌ Error: "Could not build module 'Darwin'"
- ❌ Error: "Could not build module 'Foundation'"
- ❌ Multiple "Could not build module" errors for system frameworks
- ❌ Errors mention `DerivedData/ModuleCache.noindex`

### **Root Cause**
Xcode's Swift module cache is corrupted, preventing system frameworks from being compiled.

### **Solution**

**Fix 1: Clear Module Cache**
```bash
# Remove Swift module caches
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear Xcode caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Rebuild
cd /path/to/project
flutter clean
flutter run -d <device-id>
```

**Fix 2: Clear All Swift Caches**
```bash
# Kill Xcode and Simulator
killall Xcode
killall Simulator

# Remove all caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Caches/org.swift.swiftpm

# Remove project build folder
cd /path/to/project
rm -rf build/
```

**Fix 3: Reinstall Command Line Tools**
```bash
# Remove tools
sudo rm -rf /Library/Developer/CommandLineTools

# Reinstall
xcode-select --install

# Accept license
sudo xcodebuild -license accept
```

**Fix 4: Check Disk Space**
```bash
# Check available space
df -h /

# Need at least 20GB free for builds
# If low, clean up:
# - Empty Trash
# - Delete old iOS simulators: xcrun simctl delete unavailable
# - Clean Xcode: rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Fix 5: Fix Permissions**
```bash
# Fix ownership of Developer directory
sudo chown -R $(whoami):staff ~/Library/Developer

# Fix permissions
chmod -R u+rwX ~/Library/Developer
```

### **Verification**
```bash
# Try a simple build
cd /path/to/project
flutter clean
flutter pub get
flutter run -d <device-id>
```

### **Prevention**
- Maintain at least 20GB free disk space
- Don't interrupt Xcode builds
- Let Xcode finish component installations
- Don't manually delete ModuleCache while building

---

## 8. Security Popups (idevicesyslog)

### **Symptoms**
- ❌ Popup: "idevicesyslog cannot be opened because the developer cannot be verified"
- ❌ Similar popups for other iOS tools: `idevice_id`, `ideviceinfo`, etc.
- ❌ Build proceeds but warning appears
- ❌ Popup appears every build

### **Root Cause**
macOS Gatekeeper blocks Flutter's iOS deployment tools because they're downloaded from the internet and not signed by Apple.

### **Solution**

**Method 1: Allow All Flutter iOS Tools (Recommended)**
```bash
# Find your Flutter installation
which flutter
# Example output: /Users/YOUR_USERNAME/path/to/flutter/bin/flutter

# Allow all tools in libimobiledevice
sudo xattr -cr /path/to/flutter/bin/cache/artifacts/libimobiledevice

# For example:
sudo xattr -cr /Users/Dmoney/geminiproject/development/flutter/bin/cache
```

**Method 2: Allow Individual Tools via GUI**
1. When popup appears, click **"Cancel"**
2. **System Settings** → **Privacy & Security**
3. Scroll down to find: "[tool name] was blocked from use"
4. Click **"Allow Anyway"**
5. Try building again
6. When popup reappears, click **"Open"**

**Method 3: Disable Gatekeeper (Not Recommended)**
```bash
# Disable gatekeeper temporarily
sudo spctl --master-disable

# Build your app

# Re-enable gatekeeper
sudo spctl --master-enable
```

### **Common Tools That Need Allowing**
- `idevicesyslog` - View device logs
- `idevice_id` - List device IDs
- `ideviceinfo` - Get device information
- `ideviceinstaller` - Install apps on device
- `ios-deploy` - Deploy iOS apps

### **Verification**
```bash
# Try running tool directly
/path/to/flutter/bin/cache/artifacts/libimobiledevice/idevicesyslog --version

# If it runs without popup, you're good ✅
```

### **Prevention**
- Run the `xattr -cr` command on new Flutter installations
- Allow tools when first prompted (don't keep clicking "Cancel")

---

## 9. Developer Mode Issues

### **Symptoms**
- ❌ Error: "Developer Mode disabled"
- ❌ Error: "Unable to launch app" (Developer Mode required)
- ❌ iPhone shows "Developer Mode" but it's grayed out
- ❌ App installs but won't launch

### **Root Cause**
iOS 16+ requires Developer Mode to be explicitly enabled for development.

### **Solution**

**Enable Developer Mode (iOS 16+)**

1. **On iPhone**:
   - **Settings** → **Privacy & Security** → **Developer Mode**
   - Toggle **Developer Mode ON**
   - Popup: "Turn On Developer Mode?"
   - Tap **"Restart"**

2. **After Restart**:
   - Another popup: "Turn on Developer Mode?"
   - Tap **"Turn On"**
   - Enter iPhone passcode

3. **Verify**:
   - Settings → Privacy & Security → Developer Mode
   - Should show **ON** ✅

**Alternative: USB Connection Method**

If Developer Mode option is missing:

1. **Connect iPhone to Mac via USB**
2. **Open Xcode** → **Window** → **Devices and Simulators**
3. Select your iPhone
4. Xcode may prompt: "Use for Development?"
5. Click **"Use for Development"**
6. Follow on-screen instructions

### **Troubleshooting**

**Issue: Developer Mode option not visible**
- Requires iOS 16 or later
- Update iOS: Settings → General → Software Update

**Issue: Developer Mode grayed out**
- Try connecting to Mac with Xcode open
- Try different USB cable
- Restart iPhone

**Issue: "Untrusted Developer" after enabling**
- Settings → General → VPN & Device Management
- Find your Apple ID / Developer App
- Tap → "Trust [Your Apple ID]"

### **Verification**
```bash
# Check if iPhone is ready for development
flutter devices

# Should show iPhone without warnings
```

### **Prevention**
- Enable Developer Mode on all development iPhones
- Keep iOS updated (16.0+)
- Don't disable Developer Mode during active development

---

## 10. Quick Reference Commands

### **Diagnostic Commands**

```bash
# Check Xcode version
xcodebuild -version

# Check Flutter installation
flutter doctor -v

# Check connected devices
flutter devices

# Check iOS device support files
ls /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/

# Check Xcode caches
ls -la ~/Library/Developer/Xcode/DerivedData/

# Check disk space
df -h /

# Check for CCleaner running
ps aux | grep -i ccleaner

# Find Flutter projects
find ~/Documents -name "pubspec.yaml" -maxdepth 5
```

### **Clean and Rebuild Commands**

```bash
# Flutter clean
cd /path/to/project
flutter clean
flutter pub get

# iOS clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
cd ios && pod install && cd ..

# Xcode cache clean
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Complete rebuild
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run
```

### **Emergency Reset Commands**

```bash
# Reset Xcode
killall Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# Regenerate iOS project
cd /path/to/project
cp -r ios ios_backup
rm -rf ios/Pods ios/Podfile.lock ios/Runner.xcodeproj ios/Runner.xcworkspace
flutter create --platforms=ios .
flutter pub get
cd ios && pod install && cd ..

# Reset iOS device trust
sudo rm -rf /var/db/lockdown/*
# Then reconnect iPhone and trust again
```

### **One-Liner Fixes**

```bash
# Kill CCleaner and rebuild
killall CCleaner; cd /path/to/project && flutter clean && flutter run -d DEVICE_ID

# Complete iOS reset and rebuild
cd /path/to/project && rm -rf ios/Pods ios/Podfile.lock && flutter create --platforms=ios . && flutter pub get && cd ios && pod install && cd .. && flutter run

# Clear all caches and rebuild
rm -rf ~/Library/Developer/Xcode/DerivedData && cd /path/to/project && flutter clean && flutter pub get && flutter run
```

---

## 🎯 Decision Tree: "My Build Isn't Working"

```
Build Fails
│
├─ Error mentions "stat cache file"?
│  └─ Yes → Check CCleaner, clear Xcode caches (Section 2)
│
├─ Error: "Unable to find target Runner"?
│  └─ Yes → Regenerate iOS project (Section 3)
│
├─ Wrong app opens in Xcode?
│  └─ Yes → Navigate to correct project (Section 4)
│
├─ Xcode can't run app (scheme issue)?
│  └─ Yes → Fix scheme configuration (Section 5)
│
├─ iPhone not detected?
│  └─ Yes → Enable Developer Mode, trust computer (Section 6)
│
├─ Error: "Could not build module"?
│  └─ Yes → Clear module cache (Section 7)
│
├─ Security popup appears?
│  └─ Yes → Allow Flutter tools (Section 8)
│
└─ Other issue?
   └─ Run diagnostics:
      flutter doctor -v
      xcodebuild -version
      flutter devices
```

---

## 🔍 Preventive Maintenance

### **Weekly**
```bash
# Clean Xcode caches (if needed)
rm -rf ~/Library/Developer/Xcode/DerivedData

# Update CocoaPods
pod repo update
```

### **Monthly**
```bash
# Update Flutter
flutter upgrade

# Update Xcode (via App Store)

# Check disk space
df -h /
```

### **Before Important Builds**
```bash
# Verify environment
flutter doctor -v

# Ensure CCleaner is off
killall CCleaner

# Clean rebuild
flutter clean && flutter pub get && cd ios && pod install && cd ..
```

---

## 📚 Additional Resources

### **Official Documentation**
- Flutter iOS Setup: https://docs.flutter.dev/get-started/install/macos#ios-setup
- Xcode Downloads: https://developer.apple.com/download/
- CocoaPods: https://cocoapods.org/

### **Useful Commands**
- Flutter Doctor: `flutter doctor -v`
- Xcode Version: `xcodebuild -version`
- Clear Flutter Cache: `flutter clean`
- Update Flutter: `flutter upgrade`
- Update Pods: `cd ios && pod update && cd ..`

### **Community Support**
- Flutter GitHub Issues: https://github.com/flutter/flutter/issues
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag [flutter] or [flutter-ios]

---

## ✅ Success Checklist

Your iOS build environment is healthy when:

- [ ] CCleaner is not running or has Xcode excluded
- [ ] `flutter doctor -v` shows no critical errors
- [ ] Xcode version is 15.3+ for iOS 18 devices
- [ ] `flutter devices` shows your iPhone
- [ ] iPhone has Developer Mode enabled
- [ ] Computer is trusted on iPhone
- [ ] `pod install` completes without errors
- [ ] Xcode can open `ios/Runner.xcworkspace` without issues
- [ ] `flutter run` successfully builds and installs app
- [ ] Hot reload works (`r` in terminal)

---

**Document Created**: December 13, 2025  
**Based On**: Real troubleshooting session with BeatYourRival iOS build  
**Last Updated**: December 13, 2025  
**Status**: Comprehensive guide covering all encountered issues

---

## 🎁 Summary

The most common iOS build issues we encountered:

1. **CCleaner interference** - Kill it or exclude Xcode directories
2. **Corrupted iOS project** - Regenerate with `flutter create --platforms=ios .`
3. **Xcode caching issues** - Clear with `rm -rf ~/Library/Developer/Xcode/DerivedData`
4. **Developer Mode** - Must be enabled on iOS 16+
5. **Security popups** - Allow Flutter tools with `sudo xattr -cr /path/to/flutter/bin/cache`

**Most reliable workflow:**
```bash
killall CCleaner
cd /path/to/project
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d <device-id>
```

This guide should save hours of debugging in the future! 🚀
