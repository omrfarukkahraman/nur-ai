import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart'; // import added

import '../../core/theme/app_theme.dart';
import '../premium/premium_screen.dart';
import '../../core/services/notification_service.dart'; // ✅ Eklendi
// Test butonu kalktığı için DreamInterpreter importuna gerek kalmadı, ama kalabilir sorun olmaz.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;
  String _userName = "Misafir"; // To be updated to localized string down below
  String _appVersion = "1.0.0";
  bool _notificationsEnabled = true;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint("Versiyon bilgisi alınamadı: $e");
    }

    setState(() {
      _isPremium = prefs.getBool('is_premium') ?? false;
      _userName = prefs.getString('user_name') ?? "Guest";
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);

    if (value) {
      _showSnackBar("Bildirimler açıldı");
      // Açılınca yeniden planlamak gerekir ama bunu Ana ekrana dönünce MoodScreen zaten yapacak
    } else {
      _showSnackBar("Bildirimler kapatıldı");
      // Kapandıysa tüm planlanmış bildirimleri iptal et
      await NotificationService().cancelAllPrayerNotifications(); // Sadece namazları iptal et
      // await NotificationService().cancelAll(); // Veya hepsini
    }
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Bağlantı açılamadı");
      }
    } catch (e) {
      debugPrint("Link açma hatası: $e");
      _showSnackBar("common.error".tr());
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.sageGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- VERİ YÖNETİMİ FONKSİYONLARI ---

  Future<void> _clearDreamHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dream_history');
    _showSnackBar("settings.clear_dream_success".tr());
  }

  Future<void> _confirmAction(String title, VoidCallback onConfirm) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          "common.irreversible_action".tr(),
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr(), style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("common.delete".tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "settings.title".tr(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Kartı
            _buildProfileCard(),
            const SizedBox(height: 24),

            // Premium Banner (Sadece Premium DEĞİLSE göster)
            if (!_isPremium) ...[
              _buildPremiumBanner(),
              const SizedBox(height: 32),
            ],

            // Uygulama Ayarları
            _buildSectionHeader("settings.general".tr()),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: PhosphorIcons.translate(),
                title: "settings.language".tr(),
                subtitle: context.locale.languageCode == 'en' ? 'English' : 'Türkçe',
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                onTap: () {
                  if (context.locale.languageCode == 'tr') {
                    context.setLocale(const Locale('en'));
                  } else {
                    context.setLocale(const Locale('tr'));
                  }
                  setState(() {});
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: PhosphorIcons.bell(),
                title: "settings.notifications".tr(),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: AppTheme.sageGreen,
                  inactiveTrackColor: Colors.white10,
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Veri Yönetimi
            _buildSectionHeader("settings.data_memory".tr()),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: PhosphorIcons.moonStars(),
                title: "settings.clear_dream_history".tr(),
                subtitle: "settings.clear_dream_desc".tr(),
                trailing: Icon(
                  PhosphorIcons.trash(),
                  color: Colors.redAccent.withOpacity(0.7),
                  size: 20,
                ),
                onTap: () => _confirmAction(
                    "settings.clear_dream_confirm".tr(), _clearDreamHistory),
              ),
            ]),

            const SizedBox(height: 24),

            // Destek
            _buildSectionHeader("settings.support".tr()),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: PhosphorIcons.chatCircleDots(),
                title: "settings.feedback".tr(),
                onTap: () => _openLink("mailto:support@nurai.app"),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: PhosphorIcons.star(),
                title: "settings.rate_app".tr(),
                onTap: () => _openLink("https://play.google.com/store/apps/details?id=com.nurai.pro"),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: PhosphorIcons.shareNetwork(),
                title: "settings.share_app".tr(),
                onTap: () {
                  Share.share(
                    'Nûr AI ile manevi yolculuğunu keşfet! 🌟\n\nİndir: https://play.google.com/store/apps/details?id=com.nurai.pro',
                    subject: 'Nûr AI - Yapay Zeka Destekli İslami Asistan',
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Hakkında
            _buildSectionHeader("settings.contact".tr()),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: PhosphorIcons.shieldCheck(),
                title: "settings.privacy".tr(),
                onTap: () => _openLink(
                    "https://sites.google.com/view/nurai-privacy/ana-sayfa"),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: PhosphorIcons.fileText(),
                title: "settings.terms".tr(),
                onTap: () => _openLink(
                    "https://sites.google.com/view/nurai-privacy/kullan%C4%B1m-%C5%9Fartlar%C4%B1"),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: PhosphorIcons.info(),
                title: "settings.version".tr(),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _appVersion,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ]),

            // 👇 GELİŞTİRİCİ TEST BUTONLARI ARTIK YOK! SİLİNDİ. 🧹
            const SizedBox(height: 24),

            // Sorun Giderme
            _buildSectionHeader("Sorun Giderme"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: PhosphorIcons.bellRinging(),
                title: "Bildirimleri Test Et",
                subtitle: "5 saniye sonra örnek bir bildirim gönderir.",
                onTap: () {
                  NotificationService().scheduleTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Test bildirimi 5 saniye içinde gelecek. Uygulamayı arka plana alın."),
                      backgroundColor: AppTheme.sageGreen,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ✨ Profil Kartı
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.user(PhosphorIconsStyle.fill),
              size: 28,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          // İsim ve Durum
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_isPremium)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                          size: 14,
                          color: AppTheme.premiumGold,
                        ),
                      ),
                    Text(
                      _isPremium ? "settings.premium_user".tr() : "settings.premium_guest".tr(),
                      style: GoogleFonts.outfit(
                        color: _isPremium
                            ? AppTheme.premiumGold
                            : Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Premium Banner
  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        ).then((_) => _loadData());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Mor tonlar
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "premium.title".tr(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "settings.unlock_features".tr(),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(),
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: AppTheme.sageGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            PhosphorIcons.caretRight(),
            color: Colors.white24,
            size: 16,
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 16,
      endIndent: 16,
    );
  }
}
