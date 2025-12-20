// Required imports for key.properties file loading
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    
    // Apply Google Services plugin without version here.
    // The version (4.4.0) is correctly defined in the root build.gradle file.
    id("com.google.gms.google-services") 
    
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from file (for release signing)
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

    android {
    // ... existing config ...

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}    
    }

    kotlinOptions {
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
        minSdk = flutter.minSdkVersion  // Android 5.0+
        targetSdk = 35  // Android 15 (required by Google Play)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // <--- ADD THIS LINE HERE
    }

    buildTypes {
        release {
            // Use release signing configuration
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // TEMPORARILY DISABLE code shrinking to fix ClassNotFoundException
            // TODO: Re-enable after fixing ProGuard rules
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Ensures Kotlin runtime is available
    implementation("org.jetbrains.kotlin:kotlin-stdlib") 

    // Adds Google Play Services Base package, crucial for stability with Firebase
    implementation("com.google.android.gms:play-services-base:18.4.0")
}
