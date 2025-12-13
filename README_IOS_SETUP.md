# iOS Development Setup - Quick Start

**New to iOS development with this project? Start here!**

This README provides quick links to all iOS setup and troubleshooting guides.

---

## 📚 Documentation Overview

### **For First-Time Setup**
1. **[MAC_SETUP_GUIDE.md](MAC_SETUP_GUIDE.md)** - Complete Mac + iOS development environment setup
   - Install Xcode, Flutter, CocoaPods
   - Clone repository
   - Configure signing
   - Connect iPhone
   - First build

### **Quick Start (For Experienced Developers)**
2. **[XCODE_QUICK_START.md](XCODE_QUICK_START.md)** - Fastest way to build iOS app
   - One-liner command to build and run
   - Visual guide to Xcode menus
   - Hot reload tips
   - Common keyboard shortcuts

### **When Things Break**
3. **[IOS_BUILD_TROUBLESHOOTING.md](IOS_BUILD_TROUBLESHOOTING.md)** ⭐ **MOST IMPORTANT**
   - Comprehensive troubleshooting guide
   - Based on real issues we encountered
   - 10 common problems with solutions
   - Quick reference commands
   - Decision tree for debugging

### **Specific Issues**
4. **[XCODE_SCHEME_FIX.md](XCODE_SCHEME_FIX.md)** - Fix "Executable: None" issue
5. **[IOS_PROJECT_REGENERATION_GUIDE.md](IOS_PROJECT_REGENERATION_GUIDE.md)** - Fix corrupted Runner target

---

## 🚀 Quick Commands

### **Build iOS App (Easiest Method)**
```bash
cd /Users/YOUR_USERNAME/Documents/development/apps/beatyourrival
flutter run -d 00008110-000E3C281151801E
```

### **If Build Fails, Try This First**
```bash
killall CCleaner  # Stop CCleaner if running
cd /Users/YOUR_USERNAME/Documents/development/apps/beatyourrival
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d 00008110-000E3C281151801E
```

### **Emergency Reset (If Everything Fails)**
```bash
cd /Users/YOUR_USERNAME/Documents/development/apps/beatyourrival
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter create --platforms=ios .
flutter pub get
cd ios && pod install && cd ..
flutter run -d 00008110-000E3C281151801E
```

---

## ⚠️ Critical Issues We Solved

### **1. CCleaner Breaks Xcode Builds**
**Problem**: CCleaner deletes Xcode cache files during builds  
**Solution**: Quit CCleaner or exclude `/Users/YOUR_USERNAME/Library/Developer/Xcode/`  
**Command**: `killall CCleaner`

### **2. SDK Stat Cache File Not Found**
**Problem**: Xcode cache corruption  
**Solution**: Clear Xcode caches  
**Command**: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### **3. Unable to Find Target Named 'Runner'**
**Problem**: iOS project structure corrupted  
**Solution**: Regenerate iOS project  
**Command**: `flutter create --platforms=ios .`

### **4. iPhone Not Detected**
**Problem**: Developer Mode not enabled  
**Solution**: Settings → Privacy & Security → Developer Mode → ON

### **5. Security Popups (idevicesyslog)**
**Problem**: macOS blocks Flutter iOS tools  
**Solution**: Allow tools  
**Command**: `sudo xattr -cr /path/to/flutter/bin/cache`

---

## 📖 Full Documentation Links

All guides are available on GitHub:

- **Project Assessment**: [PROJECT_ASSESSMENT.md](PROJECT_ASSESSMENT.md)
- **Action Plan**: [ACTION_PLAN.md](ACTION_PLAN.md)
- **Executive Summary**: [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)
- **Mac Setup**: [MAC_SETUP_GUIDE.md](MAC_SETUP_GUIDE.md)
- **Quick Start**: [XCODE_QUICK_START.md](XCODE_QUICK_START.md)
- **Troubleshooting**: [IOS_BUILD_TROUBLESHOOTING.md](IOS_BUILD_TROUBLESHOOTING.md) ⭐
- **Scheme Fix**: [XCODE_SCHEME_FIX.md](XCODE_SCHEME_FIX.md)
- **Project Regeneration**: [IOS_PROJECT_REGENERATION_GUIDE.md](IOS_PROJECT_REGENERATION_GUIDE.md)
- **Android Keystore**: [CREATE_ANDROID_KEYSTORE.md](CREATE_ANDROID_KEYSTORE.md)
- **Package Name Change**: [PACKAGE_NAME_CHANGE_GUIDE.md](PACKAGE_NAME_CHANGE_GUIDE.md)

---

## 🎯 Recommended Reading Order

### **Day 1: Setup**
1. Read: [MAC_SETUP_GUIDE.md](MAC_SETUP_GUIDE.md)
2. Install: Xcode, Flutter, CocoaPods
3. Clone: Repository
4. Build: First iOS app

### **Day 2: Development**
1. Read: [XCODE_QUICK_START.md](XCODE_QUICK_START.md)
2. Learn: Hot reload workflow
3. Test: Basic features on iPhone

### **When Issues Arise**
1. Check: [IOS_BUILD_TROUBLESHOOTING.md](IOS_BUILD_TROUBLESHOOTING.md)
2. Find: Your specific error
3. Apply: Recommended fix

---

## ✅ Pre-Build Checklist

Before every build, verify:

- [ ] CCleaner is NOT running: `ps aux | grep -i ccleaner`
- [ ] iPhone is connected: `flutter devices`
- [ ] iPhone is unlocked (first connection)
- [ ] Developer Mode is enabled (iOS 16+)
- [ ] You're in correct directory: `pwd`
- [ ] Project name is correct: `cat pubspec.yaml | grep name`

---

## 🆘 Getting Help

### **If You're Stuck:**

1. **Check error message** against [IOS_BUILD_TROUBLESHOOTING.md](IOS_BUILD_TROUBLESHOOTING.md)
2. **Run diagnostics**:
   ```bash
   flutter doctor -v
   xcodebuild -version
   flutter devices
   ```
3. **Try complete clean**:
   ```bash
   flutter clean
   rm -rf ~/Library/Developer/Xcode/DerivedData
   flutter pub get
   cd ios && pod install && cd ..
   ```
4. **Share output** if issue persists

### **Common Debugging Steps:**

```bash
# 1. Check Flutter installation
flutter doctor -v

# 2. Check Xcode version (need 15.3+ for iOS 18)
xcodebuild -version

# 3. Check connected devices
flutter devices

# 4. Check disk space (need 20GB+ free)
df -h /

# 5. Check for CCleaner
ps aux | grep -i ccleaner
```

---

## 🎓 Key Learnings from Our Setup

### **What Worked**
- ✅ Using Flutter CLI (`flutter run`) instead of Xcode for builds
- ✅ Stopping CCleaner completely during development
- ✅ Regenerating iOS project when corrupted
- ✅ Using device ID instead of device name
- ✅ Enabling Developer Mode immediately

### **What Didn't Work**
- ❌ Trying to build with CCleaner running
- ❌ Manually creating Xcode cache directories
- ❌ Building without Developer Mode enabled
- ❌ Using device name when it contains special characters
- ❌ Skipping `pod install` after changes

### **Best Practices**
1. **Always** run `killall CCleaner` before building
2. **Use** device ID, not device name: `flutter run -d DEVICE_ID`
3. **Clean** before major changes: `flutter clean`
4. **Update** regularly: `flutter upgrade`, Xcode via App Store
5. **Backup** working configurations before experimenting

---

## 🏆 Success Criteria

Your iOS development environment is ready when:

- [ ] `flutter doctor -v` shows no critical errors
- [ ] `flutter devices` shows your iPhone
- [ ] `flutter run -d DEVICE_ID` builds successfully
- [ ] App installs on iPhone
- [ ] App launches and shows login screen
- [ ] Hot reload works (press `r` in terminal)
- [ ] Changes appear on iPhone within seconds

---

## 📞 Support

**For project-specific questions:**
- Check: [PROJECT_ASSESSMENT.md](PROJECT_ASSESSMENT.md)
- Review: [ACTION_PLAN.md](ACTION_PLAN.md)

**For iOS build issues:**
- Start with: [IOS_BUILD_TROUBLESHOOTING.md](IOS_BUILD_TROUBLESHOOTING.md)
- Then check specific guides as needed

**For general Flutter help:**
- Official docs: https://docs.flutter.dev/
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag [flutter]

---

## 🎯 What's Next?

Once iOS builds are working:

1. **Test all features** on iPhone:
   - Registration / Login
   - Profile management
   - Battle system
   - Real-time sync
   - LiveKit video calls
   - Stripe payments

2. **Cross-platform testing**:
   - Android user vs iOS user battles
   - Verify real-time sync
   - Test push notifications

3. **Prepare for deployment**:
   - Follow [ACTION_PLAN.md](ACTION_PLAN.md)
   - Configure production signing
   - Test on TestFlight
   - Submit to App Store

---

**Happy iOS Development!** 🚀

---

**Last Updated**: December 13, 2025  
**Status**: Ready for iOS development  
**Issues Resolved**: CCleaner interference, corrupted Runner target, Xcode caching, Developer Mode
