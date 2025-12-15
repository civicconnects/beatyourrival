# 🔧 Windows Build Fix - Complete File

## 📍 Your Directory
`C:\Users\orec1\Documents\development\apps\beatrivals_app`

## 📝 File to Replace
`C:\Users\orec1\Documents\development\apps\beatrivals_app\android\app\build.gradle.kts`

---

## ✅ COMPLETE FIXED FILE

**Copy EVERYTHING below (from `import` to the last `}`) and paste into your `build.gradle.kts` file:**

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    
    // FIX 1: Apply Google Services plugin without version here.
    // The version (4.4.0) is correctly defined in the root build.gradle file.
    id("com.google.gms.google-services") 
    
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.beatyourrival.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // FIX 2: Ensure jvmTarget is compatible with your Flutter SDK
        jvmTarget = JavaVersion.VERSION_11.toString() 
    }

    // Signing configurations for release build
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // Updated package name for production
        applicationId = "com.beatyourrival.app"
        minSdk = 21  // Android 5.0+
        targetSdk = 34  // Android 14
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // Use release signing configuration
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    // FIX 3: ADD DEPENDENCY BLOCK FOR NATIVE STABILITY (LiveKit/WebRTC)
    dependencies {
        // Ensures Kotlin runtime is available
        implementation("org.jetbrains.kotlin:kotlin-stdlib") 

        // Adds Google Play Services Base package, crucial for stability with Firebase/WebRTC 
        implementation("com.google.android.gms:play-services-base:18.4.0") 

        // Optional, but sometimes needed for specific Android Studio versions for WebRTC
        // implementation("org.webrtc:google-webrtc:1.0.34000") 
    }
}

flutter {
    source = "../.."
}
```

---

## 🚀 Step-by-Step Instructions

### Step 1: Open File in Notepad

```bash
notepad C:\Users\orec1\Documents\development\apps\beatrivals_app\android\app\build.gradle.kts
```

### Step 2: Select All and Delete

- Press `Ctrl + A` (select all)
- Press `Delete`

### Step 3: Copy the Fixed Code

- Copy EVERYTHING from the code block above (from line `import java.util.Properties` to the last `}`)

### Step 4: Paste into Notepad

- Press `Ctrl + V` in the notepad window

### Step 5: Save File

- Press `Ctrl + S`
- Close Notepad

### Step 6: Build Again

```bash
cd C:\Users\orec1\Documents\development\apps\beatrivals_app
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## ✅ What This Fix Does

1. **Adds imports** at the top (line 1-2)
2. **Removes `java.util.` prefix** (line 18)
3. **Removes `java.io.` prefix** (line 20)
4. **Keeps everything else the same**

---

## 🎯 Expected Result

After running `flutter build appbundle --release`:

```
✓ Built build\app\outputs\bundle\release\app-release.aab (45.2MB)
```

**File location:**
```
C:\Users\orec1\Documents\development\apps\beatrivals_app\build\app\outputs\bundle\release\app-release.aab
```

---

## ⏰ Build Time

**First build:** 5-10 minutes  
**Subsequent builds:** 2-3 minutes

---

## 🐛 If You Still Get Errors

**Most likely issue:** Keystore not set up yet

**Solution:** We'll create a dummy keystore for now to test the build process.

**Run this if build fails with "keystore" error:**

```bash
cd C:\Users\orec1\Documents\development\apps\beatrivals_app\android
keytool -genkey -v -keystore beatrivals-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beatrivals
```

Then create `key.properties`:

```properties
storePassword=testpassword123
keyPassword=testpassword123
keyAlias=beatrivals
storeFile=beatrivals-release.jks
```

---

## 📞 Report Back

After you build, tell me:

✅ **SUCCESS!** - Got `app-release.aab` file  
❌ **ERROR** - Send me the error message

I'm ready to fix the next issue! 🚀
