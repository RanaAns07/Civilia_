# Flutter
# Keep all Flutter app, plugin, and embedding classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }

# Google Play Core Library (for SplitInstall and other features)
# These rules are necessary if your app or its dependencies use Play Core APIs,
# especially for dynamic features or app bundles.
# More comprehensive rules for Play Core to prevent R8 from stripping essential classes.
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Explicitly keep Flutter's PlayStoreDeferredComponentManager and related classes
# as they directly reference Play Core components.
# Commenting these out as they have caused "Unresolved class name" errors in previous attempts.
# If you are explicitly using Flutter's deferred components, you might need to
# re-evaluate your Flutter version or deferred component setup.
#-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
#-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }

# Keep all members of any class that implements an interface from Play Core
-keep interface com.google.android.play.core.** { *; }
-keep class * implements com.google.android.play.core.** { *; }

# Additional broad rules for Play Core to catch any remaining missing references
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.assetpacks.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }
-keep class com.google.android.play.core.review.** { *; }

# Keep all public methods and fields of classes in Play Core
-keep public class com.google.android.play.core.** {
    public *;
}
-dontwarn com.google.android.play.**


# Other Firebase plugins you might use (uncomment/add as needed)
#-keep class com.google.firebase.storage.** { *; }
#-keep class com.google.firebase.messaging.** { *; }
#-keep class com.google.firebase.analytics.** { *; }