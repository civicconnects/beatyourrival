# Mac Setup Guide for iOS Development

**Purpose**: Set up your Mac for iOS development and testing  
**Time Required**: 1-2 hours  
**Result**: Ability to build and test iOS version of BeatYourRival

---

## ✅ What You Already Have

Good news! Your project **already has iOS support**:
- ✅ `ios/` folder exists with complete configuration
- ✅ iOS-specific files already set up
- ✅ Same codebase works for both Android and iOS
- ✅ GitHub repository is cross-platform ready

**You DON'T need to start from scratch!** 🎉

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] Mac running macOS (Monterey 12.0 or later recommended)
- [ ] Internet connection
- [ ] Apple ID (free, for development)
- [ ] iPhone with USB cable
- [ ] VS Code installed on Mac
- [ ] Admin access to your Mac

---

## 🛠️ Step 1: Install Xcode (REQUIRED)

Xcode is Apple's IDE and is **absolutely required** for iOS development.

### **Option A: Install from App Store (RECOMMENDED)**

1. **Open App Store** on your Mac
2. **Search for "Xcode"**
3. **Click "Get" or "Download"** (it's free, but ~12GB!)
4. **Wait for installation** (can take 30-60 minutes depending on internet)

### **Option B: Direct Download (Faster)**

1. Go to: https://developer.apple.com/download/
2. Sign in with your Apple ID
3. Download latest Xcode
4. Install the `.xip` file

### **After Installation:**

```bash
# Accept Xcode license
sudo xcodebuild -license accept

# Install Xcode Command Line Tools
sudo xcode-select --install

# Verify installation
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer
```

---

## 🛠️ Step 2: Install Homebrew (Package Manager)

Homebrew makes installing development tools easier.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow the instructions it prints (add to PATH)
# Usually requires running these commands:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify installation
brew --version
```

---

## 🛠️ Step 3: Install Flutter on Mac

### **Download and Install Flutter:**

```bash
# Go to your home directory
cd ~

# Download Flutter (using git)
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to PATH permanently
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc

# Reload shell configuration
source ~/.zshrc

# Verify Flutter is in PATH
flutter --version
```

### **Run Flutter Doctor:**

```bash
flutter doctor -v
```

**Expected Output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x)
[✓] Xcode - develop for iOS and macOS (Xcode 15.x)
[✓] Chrome - develop for the web
[✓] VS Code (version x.x.x)
[✓] Connected device (X available)
[✓] Network resources

! Doctor found issues in 1 category.
```

### **Fix Any Issues:**

If you see warnings, follow the instructions provided by `flutter doctor`.

Common fixes:
```bash
# If CocoaPods is missing (iOS dependency manager)
sudo gem install cocoapods

# If iOS toolchain has issues
pod setup
```

---

## 🛠️ Step 4: Clone Your Repository on Mac

```bash
# Navigate to where you want the project
cd ~/Documents  # or your preferred location

# Clone from GitHub
git clone https://github.com/civicconnects/beatyourrival.git

# Enter the project directory
cd beatyourrival

# Verify you got the files
ls -la
```

**You should see:**
- `ios/` folder ✅
- `android/` folder ✅
- `lib/` folder ✅
- `pubspec.yaml` ✅

---

## 🛠️ Step 5: Install Dependencies

```bash
# Make sure you're in the project directory
cd ~/Documents/beatyourrival

# Get all Flutter packages
flutter pub get

# Install iOS-specific dependencies (CocoaPods)
cd ios
pod install
cd ..
```

**Expected Output:**
```
Running "flutter pub get" in beatyourrival...
Resolving dependencies...
Got dependencies!

Analyzing dependencies
Downloading dependencies
Installing [package names]...
Generating Pods project
Pod installation complete!
```

---

## 🛠️ Step 6: Add Firebase iOS Configuration

### **Get the iOS Firebase File:**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select Project**: "beatrivals-d8d2c"
3. **Check for iOS App**:
   - Look at the top for app icons
   - If you see iOS icon ✅ → Click it and download config
   - If NO iOS icon ❌ → Add iOS app (see below)

### **If iOS App Doesn't Exist:**

1. Click **"Add app"** button
2. Select **iOS** icon (Apple logo)
3. **iOS bundle ID**: Enter `com.example.beatrivalsApp` (or `com.civicconnects.beatrivals` if changed)
4. **App nickname**: BeatYourRival iOS
5. Click **"Register app"**
6. **Download** `GoogleService-Info.plist`

### **Add to Your Project:**

```bash
# Copy the downloaded file to your project
cp ~/Downloads/GoogleService-Info.plist ~/Documents/beatyourrival/ios/Runner/

# Verify it's there
ls -la ios/Runner/GoogleService-Info.plist
```

**IMPORTANT**: Also add this file through Xcode (next step shows how).

---

## 🛠️ Step 7: Open Project in Xcode

```bash
# Open the workspace file (NOT the project file!)
open ios/Runner.xcworkspace
```

**This will open Xcode** with your Flutter iOS project.

### **In Xcode:**

1. **Select "Runner"** in the left sidebar (project navigator)
2. **Select "Runner" target** (under TARGETS)
3. **Go to "General" tab**

### **Configure Signing:**

Under **"Signing & Capabilities"** section:

1. **Check**: "Automatically manage signing"
2. **Team**: Select your Apple ID (click "Add Account" if needed)
3. **Bundle Identifier**: Should show `com.example.beatrivalsApp`
   - If you want to change it: Update to `com.civicconnects.beatrivals`

### **Add Firebase File in Xcode:**

1. **Right-click** on "Runner" folder in left sidebar
2. Select **"Add Files to Runner"**
3. Navigate to `ios/Runner/GoogleService-Info.plist`
4. **CHECK**: "Copy items if needed"
5. **CHECK**: "Add to targets: Runner"
6. Click **"Add"**

You should now see `GoogleService-Info.plist` in the project navigator.

---

## 🛠️ Step 8: Connect Your iPhone

### **Prepare Your iPhone:**

1. **Settings** → **General** → **About**
   - Note your iOS version
2. **Settings** → **Privacy & Security** → **Developer Mode**
   - **Enable** Developer Mode
   - Restart iPhone if prompted

### **Connect to Mac:**

1. **Plug iPhone** into Mac with USB cable
2. **On iPhone**: Tap **"Trust This Computer"**
3. **Enter iPhone passcode**

### **Verify Connection:**

```bash
# In terminal, check connected devices
flutter devices
```

**Expected Output:**
```
2 connected devices:

iPhone (mobile) • 00001234-ABCD5678 • ios • iOS 17.x
macOS (desktop) • macos               • darwin-arm64 • macOS 14.x
```

If you see your iPhone listed → ✅ **Success!**

---

## 🛠️ Step 9: First iOS Build

### **Option A: Build from Terminal**

```bash
# Make sure you're in project directory
cd ~/Documents/beatyourrival

# Clean any previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for iOS (debug mode)
flutter build ios --debug --no-codesign

# Run on connected iPhone
flutter run
```

### **Option B: Build from VS Code**

1. **Open VS Code**
2. **Open folder**: `beatyourrival`
3. **View** → **Command Palette** (Cmd+Shift+P)
4. Type: **"Flutter: Select Device"**
5. Choose your **iPhone**
6. **Press F5** or click **"Run and Debug"**

### **Expected Process:**

```
Launching lib/main.dart on iPhone in debug mode...
Running pod install...
Running Xcode build...
└─Compiling, linking and signing...
✓ Built build/ios/iphoneos/Runner.app
Installing and launching...
Debug service listening on ws://127.0.0.1:xxxxx
```

### **On Your iPhone:**

The app should automatically:
1. Install on your iPhone
2. Launch automatically
3. Show the BeatYourRival login screen

---

## 🛠️ Step 10: Test the iOS App

### **First Launch Tests:**

- [ ] App icon appears on iPhone home screen
- [ ] App launches without crashing
- [ ] Login screen displays correctly
- [ ] Keyboard appears when tapping input fields

### **Basic Functionality Tests:**

- [ ] Register new account (use different email than Android)
- [ ] Login with credentials
- [ ] View home screen / dashboard
- [ ] Check profile loads
- [ ] Try searching for users
- [ ] Navigate between screens

### **Take Notes:**

Document any:
- Crashes
- UI layout issues
- Features that don't work
- Differences from Android version

---

## 🔧 Common Issues and Solutions

### **Issue 1: "Developer Mode Required"**

**Error**: Cannot launch app on iPhone

**Solution**:
1. iPhone → Settings → Privacy & Security → Developer Mode
2. Enable it
3. Restart iPhone
4. Try again

---

### **Issue 2: "Untrusted Developer"**

**Error**: "Untrusted Developer" popup on iPhone

**Solution**:
1. iPhone → Settings → General → VPN & Device Management
2. Find your Apple ID / Developer App
3. Tap → "Trust [Your Apple ID]"
4. Confirm trust
5. Try launching app again

---

### **Issue 3: Signing Failed**

**Error**: "Signing for Runner requires a development team"

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Runner target
3. Signing & Capabilities tab
4. Check "Automatically manage signing"
5. Select your Team (add Apple ID if needed)

---

### **Issue 4: CocoaPods Error**

**Error**: "pod install" fails

**Solution**:
```bash
# Update CocoaPods
sudo gem install cocoapods

# Clear pod cache
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..

# Try build again
flutter clean
flutter pub get
flutter run
```

---

### **Issue 5: Xcode Version Too Old**

**Error**: "Xcode version must be at least X.X"

**Solution**:
1. Update Xcode in App Store
2. Or download latest from developer.apple.com
3. After updating:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app
   sudo xcodebuild -license accept
   ```

---

## 🔄 Mac + Windows Workflow

### **How to Work Across Both Machines:**

```
         GitHub Repository
              ↕️ ↕️
        ┌──────┴──────┐
        ↓             ↓
     Windows         Mac
   (Android Dev)   (iOS Dev)
        ↓             ↓
   Android Phone   iPhone
```

### **Daily Workflow:**

**Morning** (Mac):
```bash
cd ~/Documents/beatyourrival
git pull origin main  # Get latest changes
flutter run           # Test on iPhone
```

**Afternoon** (Windows):
```cmd
cd C:\path\to\beatyourrival
git pull origin main  # Get latest changes
flutter run           # Test on Android
```

**End of Day** (Either machine):
```bash
git add .
git commit -m "feat: Implemented feature X"
git push origin main  # Share with other machine
```

### **Tips:**

1. **Always pull before starting work** on each machine
2. **Commit and push** at end of each session
3. **Test on both platforms** before major commits
4. **Use branches** for experimental features

---

## 📱 Testing Battles Across Platforms

Since you have both Android and iOS devices, you can test **cross-platform battles**!

### **Cross-Platform Battle Test:**

1. **Android Phone**: Login as User A
2. **iPhone**: Login as User B
3. **User A** (Android): Create battle challenge
4. **User B** (iPhone): Accept battle
5. **Play battle**: Take turns on different platforms
6. **Verify**: Moves sync correctly between platforms

This is **gold** for testing! Most developers can't do this easily. 🏆

---

## 🎯 What to Do NOW (Step by Step)

### **Today (2 hours):**

1. [ ] **Install Xcode** (30-60 min for download)
2. [ ] **Install Homebrew** (5 min)
3. [ ] **Install Flutter** on Mac (10 min)
4. [ ] **Run** `flutter doctor -v` (5 min)
5. [ ] **Clone repository** on Mac (2 min)
6. [ ] **Run** `flutter pub get` (2 min)

### **Tomorrow:**

7. [ ] **Download** `GoogleService-Info.plist` from Firebase
8. [ ] **Add** to `ios/Runner/`
9. [ ] **Open** in Xcode and configure signing
10. [ ] **Connect iPhone** and enable Developer Mode
11. [ ] **Run** `flutter run` to build iOS app
12. [ ] **Test** basic features on iPhone

### **This Week:**

13. [ ] **Test all features** on iPhone
14. [ ] **Compare** Android vs iOS behavior
15. [ ] **Test cross-platform** battles
16. [ ] **Document** any iOS-specific issues
17. [ ] **Fix bugs** found during testing

---

## 🎓 Important Mac/iOS Concepts

### **Xcode Workspace vs Project:**

- **Always open** `Runner.xcworkspace` (NOT `Runner.xcodeproj`)
- Workspace includes CocoaPods dependencies
- Project file alone won't work correctly

### **Bundle Identifier:**

- iOS equivalent of Android's package name
- Must be unique on App Store
- Format: `com.company.appname`
- Current: `com.example.beatrivalsApp`
- Production: `com.civicconnects.beatrivals`

### **Provisioning Profiles:**

- Allows app to run on your device
- Automatically managed by Xcode (usually)
- Tied to your Apple ID
- Free for development, $99/year for distribution

### **Developer Mode:**

- Required on iOS 16+ for development
- Settings → Privacy & Security → Developer Mode
- Must be enabled on iPhone for testing

---

## 📊 Mac Setup Checklist

Before you start coding, verify:

- [ ] Xcode installed and licensed
- [ ] Flutter installed on Mac
- [ ] `flutter doctor` shows no critical errors
- [ ] Repository cloned on Mac
- [ ] `flutter pub get` completed successfully
- [ ] `ios/Runner/GoogleService-Info.plist` added
- [ ] Xcode project opens without errors
- [ ] iPhone connected and trusted
- [ ] iPhone has Developer Mode enabled
- [ ] App builds and runs on iPhone
- [ ] VS Code installed on Mac (optional but recommended)

---

## 🚀 You're Ready When...

You can successfully:
- ✅ Build the app from Mac terminal
- ✅ Run app on your iPhone
- ✅ See login screen on iPhone
- ✅ Create account on iPhone
- ✅ Navigate through app screens
- ✅ Test features without crashes

---

## 💡 Pro Tips

### **Speed Up Development:**

1. **Hot Reload**: Press `r` in terminal while app is running (instant updates!)
2. **Hot Restart**: Press `R` for full restart (when hot reload isn't enough)
3. **Use Simulator**: Faster than physical device for quick tests
   ```bash
   # List simulators
   xcrun simctl list devices
   
   # Launch simulator
   open -a Simulator
   
   # Run on simulator
   flutter run
   ```

### **Debugging:**

1. **View logs** in Xcode: Window → Devices and Simulators → Select device → Open Console
2. **VS Code debugger**: Set breakpoints, inspect variables
3. **Flutter DevTools**: `flutter run` then press `v` to open DevTools

### **Keep Everything Synced:**

```bash
# Create a daily sync routine
alias sync-project='cd ~/Documents/beatyourrival && git pull origin main && flutter pub get && cd ios && pod install && cd ..'

# Run this every morning
sync-project
```

---

## 📞 Need Help?

If you encounter issues:

1. **Check Flutter Doctor**: `flutter doctor -v`
2. **Clean and Rebuild**: `flutter clean && flutter pub get`
3. **Check iOS logs**: Xcode → Window → Devices and Simulators
4. **Search error messages**: Most errors have solutions online
5. **Ask GenSpark**: I can help debug specific issues!

---

**Document Created**: December 12, 2025  
**Status**: Ready to use for Mac iOS development setup  
**Estimated Setup Time**: 2-3 hours (including downloads)
