class AppConstants {
  // --- ADMOB ---
  // ⚠️ DIKKAT: Bunlar Test ID'leridir. Markete çıkarken KESİNLİKLE gerçek ID'ler ile değiştirin!
  // Test ID'leri ile gelir elde edemezsiniz.
  // ⚠️ DIKKAT: Aşağıdakiler senin eklediğin GERÇEK AdMob ID'leridir.
  // Test ederken yine de test cihazı tanımlaman önerilir.
  static const String bannerAdUnitId = 'ca-app-pub-5113351671851564/7557194140'; // GERÇEK Banner ID
  static const String rewardedAdUnitId = 'ca-app-pub-5113351671851564/9427880918'; // GERÇEK Rewarded ID
  static const int maxDailyAds = 3;
  
  // --- REVENUECAT ---
  // Bu ID RevenueCat dashboard'da tanımladığın entitlement ID olmalı
  static const String premiumEntitlementId = 'premium';
  
  // --- LIMITLER ---
  static const int freeMessageLimit = 5;
  static const int premiumMessageLimit = 100; // Kullanıcının istediği gibi 100'e çıkarıldı
  
  static const int freeDreamLimit = 1;
  static const int premiumDreamLimit = 5;
  
  // --- SHARED PREFS KEYS ---
  static const String prefsLastAdDate = 'last_ad_date';
  static const String prefsDailyAdCount = 'daily_ad_count';
  static const String prefsLastLimitReset = 'last_limit_reset';
  static const String prefsMessageLimit = 'message_limit';
  static const String prefsDreamLimit = 'dream_limit';
  static const String prefsIsPremium = 'is_premium';
  static const String prefsDailyReminder = 'daily_reminder';
  static const String prefsQuranLanguage = 'quran_language';
  static const String prefsLastSurah = 'last_surah';
  static const String prefsLastAyah = 'last_ayah';
  static const String prefsBookmarks = 'bookmarks';
}
