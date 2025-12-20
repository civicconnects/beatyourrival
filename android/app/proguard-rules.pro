# ----------------------------------------------------------
# FLUTTER & DART WRAPPERS
# ----------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ----------------------------------------------------------
# ANDROID COMPONENTS (CRITICAL FIX)
# ----------------------------------------------------------
# Explicitly keep the constructor of your MainActivity to prevent ClassNotFoundException
-keep class com.beatyourrival.app.MainActivity {
    <init>(...);
    *;
}

# Keep all Activities, Services, etc. from Manifest
-keep public class * extends android.app.Activity
-keep public class * extends androidx.appcompat.app.AppCompatActivity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends androidx.fragment.app.Fragment

# Keep AndroidX Lifecycle (Required for FlutterActivity)
-keep class androidx.lifecycle.** { *; }
-keepclassmembers class * implements androidx.lifecycle.LifecycleObserver {
    <init>(...);
}

# ----------------------------------------------------------
# FIREBASE & GOOGLE SERVICES
# ----------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore
-keep class com.google.firestore.** { *; }
-keep class com.google.cloud.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ----------------------------------------------------------
# THIRD PARTY PLUGINS
# ----------------------------------------------------------
# Stripe
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# Video player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# ----------------------------------------------------------
# GENERIC & MODELS
# ----------------------------------------------------------
# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep model classes
-keep class com.beatyourrival.app.models.** { *; }

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}