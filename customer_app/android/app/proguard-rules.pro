# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Supabase / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core (required by Flutter deferred components)
-dontwarn com.google.android.play.core.**
