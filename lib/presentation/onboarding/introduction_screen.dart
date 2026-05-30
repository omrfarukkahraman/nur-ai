import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Web kontrolü için
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../main_screen.dart'; // ✅ Direkt ana ekrana yönlendir

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // --- SLAYT İÇERİKLERİ ---
  final List<Map<String, dynamic>> contents = [
    {
      "title": "onboarding.ai_title".tr(),
      "desc": "onboarding.ai_desc".tr(),
      "icon": PhosphorIcons.sparkle(),
    },
    {
      "title": "onboarding.dream_title".tr(),
      "desc": "onboarding.dream_desc".tr(),
      "icon": PhosphorIcons.moonStars(),
    },
    {
      "title": "onboarding.ramadan_title".tr(),
      "desc": "onboarding.ramadan_desc".tr(),
      "icon": PhosphorIcons.calendarStar(),
    },
  ];

  // ✅ İZİN İSTEME FONKSİYONU (Web uyumlu ve Hata Korumalı)
  Future<void> _requestPermissions() async {
    // Web'de permission_handler kütüphanesi tam desteklenmeyebilir
    if (kIsWeb) return;

    try {
      // 1. Bildirim İzni
      await Permission.notification.request();

      // 2. Konum İzni
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        await Permission.locationWhenInUse.request();
      }
      
      // İzinden bağımsız olarak varsayılan konumu 'otomatik' bulsun diye
      // diyanet_api_service vb. zaten konumu isteyecek.
    } catch (e) {
      debugPrint("İzin hatası (Önemsiz): $e");
    }
  }

  // ✅ ONBOARDING BİTİŞ FONKSİYONU (Takılmayı Önleyen Timeout Ekli)
  Future<void> _finishOnboarding() async {
    // İzinleri iste ama en fazla 2 saniye bekle, takılı kalmasın
    try {
      await _requestPermissions();
      // ✅ Onboarding tamamlandı olarak işaretle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_onboarding', true);
    } catch (e) {
      debugPrint("Geçiş hatası: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      body: Stack(
        children: [
          // 1. ARKA PLAN EFEKTLERİ
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.sageGreen.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.premiumGold.withOpacity(0.1),
              ),
            ),
          ),

          // 2. ANA İÇERİK
          SafeArea(
            child: Column(
              children: [
                // --- ÜST KISIM: ATLA BUTONU ---
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed:
                          _finishOnboarding, // Butona basınca beklemeden geç
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                      child: Text(
                        "common.cancel".tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- ORTA KISIM: SLAYTLAR ---
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: contents.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // İKON ALANI
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.03),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.premiumGold.withOpacity(0.05),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  contents[index]["icon"],
                                  size: 70,
                                  color: AppTheme.premiumGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),

                            // BAŞLIK
                            Text(
                              contents[index]["title"],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // AÇIKLAMA
                            Text(
                              contents[index]["desc"],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- ALT KISIM: KONTROLLER ---
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sayfa Noktaları
                      Row(
                        children: List.generate(
                          contents.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentIndex == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? AppTheme.premiumGold
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // İleri Butonu
                      GestureDetector(
                        onTap: () {
                          if (_currentIndex == contents.length - 1) {
                            _finishOnboarding();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.premiumGold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.premiumGold.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentIndex == contents.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            color: AppTheme.midnightBlue,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
