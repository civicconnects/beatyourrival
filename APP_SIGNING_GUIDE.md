# 🔐 App Signing Guide - BeatYourRival Android

**Package Name:** `com.beatyourrival.app`  
**Version:** 1.0.0 (Build 1)  
**Status:** Ready for release signing

---

## ✅ What's Already Configured

- [x] Package name updated to `com.beatyourrival.app`
- [x] Version set to 1.0.0 (versionCode: 1)
- [x] Signing configuration added to build.gradle.kts
- [x] .gitignore updated (keys won't be committed)
- [x] key.properties template created
- [x] ProGuard enabled for code obfuscation
- [x] Code shrinking enabled

---

## 🚀 Step-by-Step Instructions

### Step 1: Generate Release Keystore

**On Mac:**

```bash
cd /Users/Dmoney/Documents/development/apps/beatyourrival/android

keytool -genkey -v -keystore beatrivals-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beatrivals
```

**On Windows:**

```bash
cd C:\Users\Dmoney\Documents\development\apps\beatyourrival\android

keytool -genkey -v -keystore beatrivals-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beatrivals
```

**You'll be prompted for:**

| Prompt | Example Answer |
|--------|----------------|
| Keystore password | `BeatRival$2025!Secure` (SAVE THIS!) |
| Re-enter password | (same password) |
| First and last name | `BeatYourRival Inc` |
| Organizational unit | `Development` |
| Organization | `BeatYourRival` |
| City/Locality | `Los Angeles` |
| State/Province | `California` |
| Country code (2 letters) | `US` |
| Is this correct? | `yes` |
| Key password | (Press ENTER to use same as keystore) |

**⚠️ CRITICAL: Save your password!**
- Store in password manager (1Password, LastPass, etc.)
- Write it down and keep in safe place
- You can NEVER recover it if lost!
- Without it, you can't update your app!

---

### Step 2: Create key.properties File

**Create file:** `/Users/Dmoney/Documents/development/apps/beatyourrival/android/key.properties`

**Copy this template and fill in YOUR password:**

```properties
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=beatrivals
storeFile=beatrivals-release.jks
```

**Example (with your actual password):**

```properties
storePassword=BeatRival$2025!Secure
keyPassword=BeatRival$2025!Secure
keyAlias=beatrivals
storeFile=beatrivals-release.jks
```

**⚠️ IMPORTANT:**
- Replace `YOUR_KEYSTORE_PASSWORD_HERE` with your actual password
- If you used different passwords for keystore and key, update both
- Most people use the same password for both (simpler)

---

### Step 3: Verify Files Exist

**Check that these files exist:**

```bash
# On Mac:
ls -la /Users/Dmoney/Documents/development/apps/beatyourrival/android/

# Should see:
# - beatrivals-release.jks (your keystore)
# - key.properties (your passwords)
```

**On Windows:**

```bash
dir C:\Users\Dmoney\Documents\development\apps\beatyourrival\android\

# Should see:
# - beatrivals-release.jks
# - key.properties
```

---

### Step 4: Update Package Name in Android Manifest

**File:** `android/app/src/main/AndroidManifest.xml`

Make sure the package at the top matches: `com.beatyourrival.app`

If not, update line 2:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.beatyourrival.app">
```

---

### Step 5: Build Release AAB

**On Mac:**

```bash
cd /Users/Dmoney/Documents/development/apps/beatyourrival

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release AAB
flutter build appbundle --release
```

**On Windows:**

```bash
cd C:\Users\Dmoney\Documents\development\apps\beatyourrival

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release AAB
flutter build appbundle --release
```

**Build time:** 5-10 minutes (first time)

**Output file location:**
- Mac: `/Users/Dmoney/Documents/development/apps/beatyourrival/build/app/outputs/bundle/release/app-release.aab`
- Windows: `C:\Users\Dmoney\Documents\development\apps\beatyourrival\build\app\outputs\bundle\release\app-release.aab`

---

### Step 6: Test Release Build on Device

**Build and install release APK (for testing only):**

```bash
flutter build apk --release
flutter install --release
```

**Or install directly:**

```bash
flutter run --release
```

**Test checklist:**
- [ ] App opens successfully
- [ ] No crashes
- [ ] Login works
- [ ] Video recording works
- [ ] Video upload works
- [ ] Video playback works
- [ ] Battles work
- [ ] All features functional

---

## 🔒 Security Best Practices

### ✅ DO:
- [x] Keep `beatrivals-release.jks` safe (backup in multiple locations)
- [x] Keep `key.properties` secret (never commit to Git)
- [x] Use strong password (12+ characters, symbols, numbers)
- [x] Store password in password manager
- [x] Backup keystore to Google Drive, Dropbox, or USB drive
- [x] Keep keystore for 10,000 days (27 years validity)

### ❌ DON'T:
- [ ] Commit keystore or key.properties to Git (already protected by .gitignore)
- [ ] Share keystore or passwords publicly
- [ ] Lose your keystore (can't update app without it!)
- [ ] Use weak passwords
- [ ] Store passwords in plain text files

---

## 📦 File Sizes

**Typical sizes:**
- `app-release.aab`: 30-50 MB (upload to Play Store)
- `app-release.apk`: 35-55 MB (for manual testing)

---

## 🐛 Common Issues & Solutions

### Issue 1: "keytool: command not found"

**Cause:** Java JDK not installed or not in PATH

**Solution (Mac):**
```bash
# Install Java if needed
brew install openjdk@11

# Add to PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Solution (Windows):**
- Install Java JDK from: https://www.oracle.com/java/technologies/downloads/
- Add Java bin folder to PATH environment variable

---

### Issue 2: "Keystore file does not exist"

**Cause:** key.properties points to wrong location

**Solution:**
- Verify `beatrivals-release.jks` exists in `android/` folder
- Check `storeFile` path in `key.properties`
- Should be: `storeFile=beatrivals-release.jks` (relative path)

---

### Issue 3: "Build failed: signing configuration not found"

**Cause:** `key.properties` file doesn't exist or has wrong content

**Solution:**
- Verify `android/key.properties` file exists
- Check file has all 4 properties (storePassword, keyPassword, keyAlias, storeFile)
- Verify no typos in property names
- Ensure passwords don't have trailing spaces

---

### Issue 4: "Incorrect keystore password"

**Cause:** Wrong password in key.properties

**Solution:**
- Double-check password (case-sensitive!)
- Try re-creating `key.properties` file
- If you forgot password, you must generate new keystore (and use new package name)

---

### Issue 5: Build succeeds but app won't install

**Cause:** Package name mismatch or signing issue

**Solution:**
- Uninstall old debug version first: `adb uninstall com.example.beatrivals_app`
- Then install release: `flutter install --release`

---

## 📋 Pre-Submit Checklist

Before uploading to Google Play Store:

- [ ] Keystore generated and backed up
- [ ] key.properties created with correct passwords
- [ ] AAB file built successfully
- [ ] Release APK tested on physical device
- [ ] All features work in release mode
- [ ] No debug code or test data in app
- [ ] Version number correct (1.0.0)
- [ ] Package name correct (com.beatyourrival.app)
- [ ] App icon set
- [ ] Splash screen configured

---

## 🎯 Next Steps After Signing

Once AAB is built:

1. **Test thoroughly** on real devices
2. **Create store assets** (screenshots, feature graphic)
3. **Write Privacy Policy** and Terms of Service
4. **Set up Google Play Console** account
5. **Upload AAB** to Play Console
6. **Submit for review**
7. **Launch!** 🚀

---

## 💾 Backup Checklist

**Immediately after generating keystore, backup:**

1. **Keystore file:** `beatrivals-release.jks`
   - Copy to Google Drive
   - Copy to Dropbox
   - Copy to USB drive
   - Copy to external hard drive

2. **Passwords document:**
   - Store in 1Password/LastPass/Bitwarden
   - Write on paper, keep in safe
   - Email encrypted copy to yourself

3. **key.properties file:**
   - Backup to secure cloud storage
   - Keep copy on separate device

**Remember:** Without the keystore and password, you CANNOT publish updates to your app!

---

## 🔗 Useful Links

- **Flutter Release Docs:** https://docs.flutter.dev/deployment/android
- **Android App Signing:** https://developer.android.com/studio/publish/app-signing
- **Google Play Console:** https://play.google.com/console

---

## ✅ Summary

**Package Name:** `com.beatyourrival.app`  
**Version:** 1.0.0 (Build 1)  
**Keystore:** `beatrivals-release.jks`  
**Alias:** `beatrivals`  
**Validity:** 10,000 days  

**Status:** 🟢 Ready to build release!

**Command to build:**
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

This AAB file is what you'll upload to Google Play Store! 🚀
