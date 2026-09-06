-keep class ai.onnxruntime.** { *; }

-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.android.billingclient.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

-keep class com.antonkarpenko.ffmpegkit.FFmpegKitConfig {
    native <methods>;
    void log(long, int, byte[]);
    void statistics(long, int, float, float, long, double, double, double);
    int safOpen(int);
    int safClose(int);
}

-keep class com.antonkarpenko.ffmpegkit.AbiDetect {
    native <methods>;
}
