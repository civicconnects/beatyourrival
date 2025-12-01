plugins {
    id("com.android.application")
    id("kotlin-android")
    
    // FIX 1: Apply Google Services plugin without version here.
    // The version (4.4.0) is correctly defined in the root build.gradle file.
    id("com.google.gms.google-services") 
    
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.beatrivals_app"
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

    defaultConfig {
        applicationId = "com.example.beatrivals_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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