// lib/presentation/quran/surah_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/quran_service.dart';
import 'surah_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  final _quranService = QuranService();
  List<SurahInfo>? _surahs;
  Map<String, int> _lastRead = {'surah': 1, 'ayah': 1};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final surahs = await _quranService.getAllSurahs();
    final lastRead = await _quranService.getLastRead();

    setState(() {
      _surahs = surahs;
      _lastRead = lastRead;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
              color: AppTheme.premiumGold,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Kur'an-ı Kerim",
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.premiumGold,
              ),
            )
          : Column(
              children: [
                // Son Okunan Kartı
                _buildLastReadCard(),
                const SizedBox(height: 16),

                // Sure Listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _surahs!.length,
                    itemBuilder: (context, index) {
                      final surah = _surahs![index];
                      return _buildSurahCard(surah);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLastReadCard() {
    final surah = _surahs?.firstWhere(
      (s) => s.number == _lastRead['surah'],
      orElse: () => _surahs!.first,
    );

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.sageGreen.withOpacity(0.2),
            AppTheme.premiumGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sageGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sageGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.bookBookmark(PhosphorIconsStyle.fill),
              color: AppTheme.sageGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kaldığın Yer",
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  surah?.transliteration ?? 'Al-Fatihah',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Ayet ${_lastRead['ayah']}",
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surahNumber: _lastRead['surah']!,
                    startAyah: _lastRead['ayah']!,
                  ),
                ),
              );
              _loadData(); // Geri dönünce yenile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Devam Et",
              style: GoogleFonts.outfit(
                color: AppTheme.midnightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(SurahInfo surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(
                surahNumber: surah.number,
              ),
            ),
          );
          _loadData(); // Geri dönünce yenile
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.premiumGold.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.premiumGold.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              "${surah.number}",
              style: GoogleFonts.outfit(
                color: AppTheme.premiumGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          ref.watch(settingsProvider).language == 'tr'
              ? (surah.nameTr ?? surah.nameEn)
              : surah.nameEn,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "${surah.versesCount} Ayet · ${surah.revelationType}",
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          surah.nameAr,
          style: GoogleFonts.amiri(
            color: AppTheme.premiumGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
