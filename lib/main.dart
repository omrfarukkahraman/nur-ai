import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nur_ai/core/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Kendi dosya yolların
import 'package:nur_ai/core/services/notification_service.dart';
import 'package:nur_ai/core/services/rewarded_ad_manager.dart';
import 'package:nur_ai/core/theme/app_theme.dart';
import 'package:nur_ai/presentation/main_screen.dart';
import 'package:nur_ai/presentation/onboarding/introduction_screen.dart';
import 'package:nur_ai/presentation/splash/splash_screen.dart'; // Splash ekranını kullanıyoruz
import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized(); // 👈 Çeviri başlat

  // 👇 .env dosyasını yükle
  await dotenv.load(fileName: ".env");
  // ücret
  await PurchaseService().init();
  // 1. Dil ve Tarih
  await initializeDateFormatting('tr_TR', null);
  // 2. Bildirimler
  await NotificationService().init();
  // 3. Reklam (Mobilde)
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    RewardedAdManager().loadAd();
  }
  // 4. Status Bar Rengi
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations', // <-- JSON dosyalarının yolu
      fallbackLocale: const Locale('en'), // Bulunamazsa EN yap (Global kitle için)
      assetLoader: const RootBundleAssetLoader(), // Eklendi (Web sorunlarına karşı garanti)
      child: const ProviderScope(
        child: NurAIApp(),
      ),
    ),
  );
}

class NurAIApp extends StatelessWidget {
  const NurAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nûr AI',
      localizationsDelegates: context.localizationDelegates, // Dil delege
      supportedLocales: context.supportedLocales, // Desteklenen diller
      locale: context.locale, // Cihaz dilini otomatik alır veya ayarlanan dili kullanır
      theme: AppTheme.lightTheme,
      // Artık direkt Splash ekranına gidiyoruz, o bizi yönlendirecek
      home: const SplashScreen(),
    );
  }
}
