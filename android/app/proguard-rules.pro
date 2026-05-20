# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# Keep all classes in our app
-keep class com.smartattendance.app.** { *; }

# General Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
