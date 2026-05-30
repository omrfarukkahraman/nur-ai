import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

// Mevcut Araçlar
import 'zikirmatik_screen.dart';
import 'prayer_book_screen.dart';
import 'qada_tracker_screen.dart';
import 'esma_screen.dart';
import 'qibla_compass_screen.dart';
import 'dream_interpreter_screen.dart'; // Aşağıda oluşturuluyor
import '../quran/surah_list_screen.dart'; // Aşağıda oluşturuluyor
import 'ramadan_calendar_screen.dart';
import 'mukabele_tracker_screen.dart';

import 'zakat_calculator_screen.dart'; // YENİ EKLENDİ

import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "tools.title".tr(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GÜNLÜK İbadetler
            _buildCategoryTitle("tools.daily_worship".tr(), PhosphorIcons.sunHorizon()),
            const SizedBox(height: 12),
            _buildPremiumGrid(
              context,
              crossAxisCount: 2,
              items: [
                _ToolItem("tools.quran".tr(), "tools.quran_desc".tr(), PhosphorIcons.bookOpenText(), const Color(0xFF10B981), const SurahListScreen()),
                _ToolItem("tools.qibla".tr(), "tools.qibla_desc".tr(), PhosphorIcons.compass(), const Color(0xFF3B82F6), const QiblaCompassScreen()),
                _ToolItem("tools.prayer".tr(), "tools.prayer_desc".tr(), PhosphorIcons.handsPraying(), const Color(0xFFA1887F), const PrayerBookScreen()),
                _ToolItem("tools.zikir".tr(), "tools.zikir_desc".tr(), PhosphorIcons.handGrabbing(), const Color(0xFF64748B), const ZikirmatikScreen()),
              ]
            ),
            const SizedBox(height: 32),

            // RAMAZAN ÖZEL
            _buildCategoryTitle("tools.ramadan".tr(), PhosphorIcons.moonStars(), color: AppTheme.premiumGold),
            const SizedBox(height: 12),
            _buildPremiumGrid(
              context,
              crossAxisCount: 2,
              items: [
                _ToolItem("tools.imsakiye".tr(), "tools.imsakiye_desc".tr(), PhosphorIcons.calendarStar(), AppTheme.premiumGold, const RamadanCalendarScreen()),
                _ToolItem("tools.mukabele".tr(), "tools.mukabele_desc".tr(), PhosphorIcons.bookBookmark(), AppTheme.sageGreen, const MukabeleTrackerScreen()),
                _ToolItem("tools.zakat".tr(), "tools.zakat_desc".tr(), PhosphorIcons.coins(), const Color(0xFFFDE047), const ZakatCalculatorScreen()),
                _ToolItem("tools.kaza".tr(), "tools.kaza_desc".tr(), PhosphorIcons.clockCounterClockwise(), const Color(0xFFEF4444), const QadaTrackerScreen()),
              ]
            ),
            const SizedBox(height: 32),

            // KENDİNİ KEŞFET
            _buildCategoryTitle("tools.explore".tr(), PhosphorIcons.sparkle(), color: const Color(0xFF9333EA)),
            const SizedBox(height: 12),
            _buildPremiumGrid(
              context,
              crossAxisCount: 1, // Yatay uzun kartlar
              aspectRatio: 3.5,
              items: [
                _ToolItem("tools.dream".tr(), "tools.dream_desc".tr(), PhosphorIcons.moon(), const Color(0xFF9333EA), const DreamInterpreterScreen()),
                _ToolItem("tools.esma".tr(), "tools.esma_desc".tr(), PhosphorIcons.starFour(PhosphorIconsStyle.fill), AppTheme.premiumGold, const EsmaScreen()),
              ]
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTitle(String title, IconData icon, {Color color = Colors.white}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGrid(BuildContext context, {required int crossAxisCount, double aspectRatio = 1.1, required List<_ToolItem> items}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPremiumCard(context, item, isWide: crossAxisCount == 1);
      },
    );
  }

  Widget _buildPremiumCard(BuildContext context, _ToolItem item, {bool isWide = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => item.screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              item.color.withOpacity(0.15),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(color: item.color.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: item.color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: item.color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1),
                      const SizedBox(height: 4),
                      Text(item.subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ToolItem(this.title, this.subtitle, this.icon, this.color, this.screen);
}
