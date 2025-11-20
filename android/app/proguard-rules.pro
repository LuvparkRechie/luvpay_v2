# Keep JSON-related classes
-keep class * extends com.applozic.mobicommons.json.JsonMarker {
    !static !transient <fields>;
}

-keepclassmembernames class * extends com.applozic.mobicommons.json.JsonParcelableMarker {
    !static !transient <fields>;
}

# GSON Configuration
-keepattributes Signature
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.examples.android.model.** { *; }
-keep class org.eclipse.paho.client.mqttv3.logging.JSR47Logger { *; }
-keep class android.support.** { *; }
-keep interface android.support.** { *; }
-dontwarn android.support.v4.**
-keep public class com.google.android.gms.* { public *; }
-dontwarn com.google.android.gms.**
-keep class com.google.gson.** { *; }

# 🔹 Keep Flutter MethodChannel functionality
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# 🔹 Keep MainActivity and prevent obfuscation of root detection logic
-keep class com.cmds.luvpark.MainActivity { *; }
-keepclassmembers class com.cmds.luvpark.MainActivity { 
    public <methods>; 
}

# 🔹 Keep root detection methods (prevent ProGuard from removing them)
-keepclassmembers class * {
    public boolean isRooted();
    public boolean checkRootMethod1();
    public boolean checkRootMethod2();
    public boolean checkRootMethod3();
}

# 🔹 Prevent ProGuard from optimizing or removing Runtime.exec() calls
-keep class java.lang.Runtime { *; }

# 🔹 Keep File class for root file detection
-keep class java.io.File { *; }

# 🔹 Prevent ProGuard from stripping log messages (Optional: If you want logs in release)
-dontwarn android.util.Log
