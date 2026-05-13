# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase + Crashlytics symbolication
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keepattributes SourceFile,LineNumberTable

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Play Core (required for Flutter deferred components / R8 compatibility)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# In-App Purchase / Play Billing — FiyatRadar Pro aboneliği
-keep class com.android.billingclient.api.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.billingclient.api.**

# Mobile Scanner (barkod tarayıcı) — ZXing + ML Kit
-keep class com.google.zxing.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.tflite.dynamite.**

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# local_auth (biyometrik)
-keep class androidx.biometric.** { *; }
-keep class androidx.fragment.app.FragmentActivity { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# Geolocation
-keep class com.baseflow.geolocator.** { *; }

# Keep generic Parcelable / Serializable patterns that Firebase relies on
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
