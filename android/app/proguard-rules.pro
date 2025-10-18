###########################################################
# Flutter & Dart
###########################################################
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }


###########################################################
# SQFlite & SQLite
###########################################################
-keep class android.database.sqlite.** { *; }
-keep class sqflite.** { *; }

###########################################################
# Hive Database
###########################################################
-keep class *.Adapter { *; }
-keep class **.hive.** { *; }

###########################################################
# Google Mobile Ads SDK
###########################################################
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

###########################################################

# JNI / Native Methods
###########################################################
-keepclasseswithmembernames class * {
    native <methods>;
}

###########################################################
# Miscellaneous
###########################################################
-dontwarn io.flutter.embedding.**
-dontwarn com.google.ads.**
-dontwarn com.google.android.gms.**
-dontwarn androidx.**
-dontwarn org.jetbrains.**
