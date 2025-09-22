# Flutter için gerekli
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase için gerekli
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# AdMob ve Google Ads için gerekli
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Gson varsa
-keep class com.google.gson.** { *; }

# URL launcher için
-keep class io.flutter.plugins.urllauncher.** { *; }

# Flutter'ın dynamic feature module (SplitInstall) hatası çözümü
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
