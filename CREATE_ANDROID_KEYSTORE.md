# How to Create Android Release Keystore

## What is a Keystore?
A keystore is a file that stores your app's signing key. You need this to publish to Google Play Store.

⚠️ **CRITICAL WARNING**: 
- If you lose this file, you **CANNOT update your app** on Google Play Store
- You would have to publish a completely new app with a new package name
- **Back up this file immediately after creating it!**

---

## Step 1: Create the Keystore

### Option A: Using Command Line (Windows)

Open **Command Prompt** or **PowerShell** as Administrator:

```cmd
cd C:\path\to\beatyourrival

keytool -genkey -v -keystore beatrivals-release.keystore ^
  -alias beatrivals ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000
```

### Option B: Using Git Bash (if you have it)

```bash
cd /c/path/to/beatyourrival

keytool -genkey -v -keystore beatrivals-release.keystore \
  -alias beatrivals \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

---

## Step 2: Answer the Prompts

The command will ask you several questions:

```
Enter keystore password: [CREATE STRONG PASSWORD]
Re-enter new password: [REPEAT PASSWORD]

What is your first and last name?
  [You]: Your Name or Company Name

What is the name of your organizational unit?
  [You]: Development Team (or skip by pressing Enter)

What is the name of your organization?
  [You]: Civic Connects (or your organization)

What is the name of your City or Locality?
  [You]: Your City

What is the name of your State or Province?
  [You]: Your State

What is the two-letter country code for this unit?
  [You]: US (or your country code)

Is CN=Your Name, OU=Development, O=Civic Connects, L=City, ST=State, C=US correct?
  [You]: yes

Enter key password for <beatrivals>
  (RETURN if same as keystore password): [Press ENTER or create different password]
```

---

## Step 3: Save Your Credentials SECURELY

**IMMEDIATELY** write down these details in a **SECURE** location:

```
Keystore File: beatrivals-release.keystore
Keystore Password: [YOUR_PASSWORD_HERE]
Key Alias: beatrivals
Key Password: [SAME_AS_KEYSTORE_OR_DIFFERENT]
```

**Storage Recommendations**:
- ✅ Password manager (LastPass, 1Password, Bitwarden)
- ✅ Encrypted USB drive
- ✅ Secure cloud storage (with encryption)
- ❌ Plain text file on desktop
- ❌ Sticky note
- ❌ Git repository

---

## Step 4: Create key.properties File

Create a file at `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=beatrivals
storeFile=../beatrivals-release.keystore
```

**Replace**:
- `YOUR_KEYSTORE_PASSWORD_HERE` with your actual keystore password
- `YOUR_KEY_PASSWORD_HERE` with your actual key password (or same as keystore)

---

## Step 5: Update .gitignore

Add these lines to `.gitignore`:

```
# Android signing
android/key.properties
*.keystore
*.jks
```

This prevents accidentally committing your signing keys to GitHub.

---

## Step 6: Update build.gradle.kts

The file is already partially configured at `android/app/build.gradle.kts`.

You need to add the signing configuration loading at the top:

```kotlin
// Add this at the top of the file, after the plugins block
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Enables code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## Step 7: Test the Signing Configuration

```bash
# Build a release APK (signed with your keystore)
flutter build apk --release

# Or build an App Bundle for Play Store
flutter build appbundle --release
```

If successful, you'll find the signed file at:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 8: Verify the Signing

```bash
# Check APK signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

You should see your certificate details (name, organization, etc.)

---

## ⚠️ BACKUP CHECKLIST

Before proceeding, ensure you have backed up:

- [ ] `beatrivals-release.keystore` file (the keystore itself)
- [ ] Keystore password (written down securely)
- [ ] Key alias (should be "beatrivals")
- [ ] Key password (written down securely)
- [ ] Store in **2+ separate secure locations**

**Why?** If you lose this, you can NEVER update your app on Google Play Store!

---

## When Do You Need This?

- ❌ **Not needed for**: Debug builds, testing, emulator
- ✅ **Needed for**: Publishing to Google Play Store, production releases

So you can **skip this for now** if you're still in the testing phase.

---

## iOS Signing (Separate Process)

iOS signing is different and requires:
1. Apple Developer Account ($99/year)
2. Certificate Signing Request (CSR)
3. Distribution Certificate
4. Provisioning Profile

This is typically done through **Xcode** on a Mac. I can provide instructions when you're ready.

---

**Document Created**: December 12, 2025  
**For**: BeatYourRival App Signing
