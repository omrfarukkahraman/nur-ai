# Flutter Local Notifications (Bildirimler için)
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Google Mobile Ads (Reklamlar için)
-keep class com.google.android.gms.ads.** { *; }

# Timezone & Tarih (Uygulamanın açılmama sebebi bu!)
-keep class net.time4j.** { *; }
-keep class java.time.** { *; }
-keep class org.threeten.bp.** { *; }

# RevenueCat (Satın alma için)
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.** { *; }

# Genel Flutter Wrapper koruması
-keep class io.flutter.plugin.** { *; }