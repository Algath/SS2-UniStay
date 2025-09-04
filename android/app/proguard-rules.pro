# TensorFlow Lite – garder toutes les classes
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }

# GPU delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# JNI / native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Retain enums
-keepclassmembers enum * { *; }

# Suppress warnings generated automatically by Android Gradle plugin
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
