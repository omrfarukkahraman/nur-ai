import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

// --- TEMA VE SAYFA IMPORTLARI ---
import '../core/theme/app_theme.dart';
import '../core/services/purchase_service.dart';
import '../core/services/notification_service.dart';
import '../core/constants/app_constants.dart';
import 'onboarding/mood_screen.dart'; // Anasayfa olarak Mood seçimi
import 'tools/tools_hub_screen.dart'; // Araçlar
import 'tools/settings_screen.dart'; // Profil/Ayarlar
import 'chat/chat_screen.dart'; // Sohbet Ekranı
import 'widgets/banner_ad_widget.dart'; // Banner Reklam

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAndResetLimits(); 
    // İzinler artık SplashScreen'de isteniyor, burada tekrar istemiyoruz.
  }

  // ✅ GÜNLÜK LİMİT SIFIRLAMA (Her gün otomatik)
  Future<void> _checkAndResetLimits() async {
    final prefs = await SharedPreferences.getInstance();

    // Premium durumu kontrol
    await PurchaseService().checkSubscriptionStatus();
    final isPremium = PurchaseService().isPremium;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastReset = prefs.getString(AppConstants.prefsLastLimitReset) ?? '';

    // Gün değiştiyse limitleri sıfırla
    if (lastReset != today) {
      debugPrint('📅 Yeni gün! Limitler sıfırlanıyor...');

      await prefs.setString(AppConstants.prefsLastLimitReset, today);

      // Chat mesaj limiti
      final chatLimit = isPremium ? AppConstants.premiumMessageLimit : AppConstants.freeMessageLimit;
      await prefs.setInt(AppConstants.prefsMessageLimit, chatLimit);

      // Rüya tabiri limiti
      final dreamLimit = isPremium ? AppConstants.premiumDreamLimit : AppConstants.freeDreamLimit;
      await prefs.setInt(AppConstants.prefsDreamLimit, dreamLimit);

      // Reklam izleme sayacını sıfırla (Günlük 3 reklam)
      await prefs.setInt(AppConstants.prefsDailyAdCount, 0);

      debugPrint('✅ Limitler sıfırlandı: Chat=$chatLimit, Dream=$dreamLimit');
    } else {
      debugPrint('📊 Bugün için limitler zaten ayarlanmış');
    }
  }

  // Alt Menüdeki Sayfalar
  List<Widget> get _screens => [
        const MoodScreen(), // 0: Anasayfa
        Container(), // 1: Sohbet (Tıklanınca Mood Screen açılır)
        const ToolsHubScreen(), // 2: Araçlar
        const SettingsScreen(), // 3: Profil
      ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // Sohbet sekmesine tıklandı
      // MoodScreen'e gitmek yerine ChatScreen'i aç
      // Ama önce mood seçmeli, o yüzden MoodScreen'e yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ChatScreen(mood: "Genel")),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,

      // IndexedStack: Sayfalar arası geçişte durumu (state) korur.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Reklam (Sadece Premium değilse)
          FutureBuilder(
            future: PurchaseService().isInitialized
                ? Future.value(PurchaseService().isPremium)
                : PurchaseService().checkSubscriptionStatus().then((_) => PurchaseService().isPremium),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == false) {
                return const BannerAdWidget();
              }
              return const SizedBox.shrink();
            },
          ),
          
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withOpacity(0.05), width: 1)),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.all(
                  GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70),
                ),
                iconTheme: WidgetStateProperty.all(
                  const IconThemeData(color: Colors.white54),
                ),
              ),
// ... [existing code]
              child: NavigationBar(
                height: 70,
                backgroundColor: AppTheme.midnightBlue,
                indicatorColor: AppTheme.premiumGold.withOpacity(0.2),
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabTapped, // ✅ Özel fonksiyon
                destinations: [
                  // 1. ANASAYFA
                  NavigationDestination(
                    icon: Icon(PhosphorIcons.house()),
                    selectedIcon: Icon(
                        PhosphorIcons.house(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold),
                    label: 'bottom_nav.home'.tr(),
                  ),

                  // 2. SOHBET
                  NavigationDestination(
                    icon: Icon(PhosphorIcons.chatTeardropText()),
                    selectedIcon: Icon(
                        PhosphorIcons.chatTeardropText(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold),
                    label: 'bottom_nav.chat'.tr(),
                  ),

                  // 3. ARAÇLAR
                  NavigationDestination(
                    icon: Icon(PhosphorIcons.squaresFour()),
                    selectedIcon: Icon(
                        PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold),
                    label: 'bottom_nav.tools'.tr(),
                  ),

                  // 4. PROFİL
                  NavigationDestination(
                    icon: Icon(PhosphorIcons.user()),
                    selectedIcon: Icon(
                        PhosphorIcons.user(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold),
                    label: 'bottom_nav.profile'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
