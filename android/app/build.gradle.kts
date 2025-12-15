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