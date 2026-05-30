import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nur_ai/core/theme/app_theme.dart';
import 'package:nur_ai/presentation/main_screen.dart';
import 'package:nur_ai/presentation/onboarding/introduction_screen.dart';
import 'package:nur_ai/core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // 1. Kullanıcı verisini kontrol et (izinlerle paralel çalışsın)
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    // 2. Minimum branding süresi (logo gösterimi)
    final brandingDelay = Future.delayed(const Duration(milliseconds: 1500));

    // 3. İzinleri iste ve SONUCUNU BEKLE
    // Android 13+ için bu kritik: kullanıcı "İzin Ver" diyene kadar bekler.
    await NotificationService().requestPermissions();
    debugPrint('✅ İzin akışı tamamlandı');

    // 3.5 Pil optimizasyonu baypas isteği (Arka planda kapanmaması için)
    await NotificationService().requestBatteryOptimizationBypass();

    // 4. Branding süresi dolmadıysa bekle (çok hızlı izin verildiyse logo en az 1.5 sn görünsün)
    await brandingDelay;

    if (mounted) {
      // 5. Sayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              seenOnboarding ? const MainScreen() : const IntroductionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue, // Tema rengini kullan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),

            // Loading indicator (Opsiyonel - Daha profesyonel görünüm)
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.premiumGold.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
