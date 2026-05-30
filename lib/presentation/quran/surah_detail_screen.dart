// lib/presentation/quran/surah_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/quran_service.dart';
import '../../core/models/quran_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';

class SurahDetailScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  final int startAyah;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.startAyah = 1,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final _quranService = QuranService();
  final ScrollController _scrollController = ScrollController();
  QuranSurah? _surah;
  bool _isLoading = true;
  double _fontSize = 24.0;
  bool _showMeal = true;
  Map<String, bool> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    setState(() => _isLoading = true);

    final surah = await _quranService.loadSurah(widget.surahNumber);

    // Yer imlerini yükle
    final bookmarksList = await _quranService.getBookmarks();
    final bookmarks = <String, bool>{};
    for (var b in bookmarksList) {
      if (b['surah'] == widget.surahNumber) {
        bookmarks['${b['surah']}:${b['ayah']}'] = true;
      }
    }

    setState(() {
      _surah = surah;
      _bookmarks = bookmarks;
      _isLoading = false;
    });

    // Son okunan yeri kaydet
    _quranService.saveLastRead(widget.surahNumber, widget.startAyah);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _surah == null) {
      return Scaffold(
        backgroundColor: AppTheme.midnightBlue,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.premiumGold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              _surah!.name.transliteration,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _surah!.name.ar,
              style: GoogleFonts.amiri(
                color: AppTheme.premiumGold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Font Boyutu
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields, color: Colors.white),
            onSelected: (size) => setState(() => _fontSize = size),
            itemBuilder: (context) => [
              PopupMenuItem(value: 18.0, child: Text("common.small".tr())),
              const PopupMenuItem(value: 24.0, child: Text("Normal")),
              PopupMenuItem(value: 30.0, child: Text("common.big".tr())),
            ],
          ),
          // Meal Dili Değiştir
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (lang) {
               ref.read(settingsProvider.notifier).setLanguage(lang);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'tr', child: Text("common.turkish".tr())),
              const PopupMenuItem(value: 'en', child: Text("English")),
            ],
          ),
          // Meal Göster/Gizle
          IconButton(
            icon: Icon(
              _showMeal
                  ? PhosphorIcons.eye(PhosphorIconsStyle.fill)
                  : PhosphorIcons.eyeSlash(),
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showMeal = !_showMeal),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sure Bilgi Kartı
          _buildSurahInfoCard(),
          const SizedBox(height: 16),

          // Ayetler
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _surah!.verses.length,
              itemBuilder: (context, index) {
                final verse = _surah!.verses[index];
                return _buildAyahCard(verse);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.premiumGold.withOpacity(0.1),
            AppTheme.sageGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: PhosphorIcons.article(),
            label: "Ayetler",
            value: "${_surah!.versesCount}",
          ),
          _buildInfoItem(
            icon: PhosphorIcons.chatText(),
            label: "Kelimeler",
            value: "${_surah!.wordsCount}",
          ),
          _buildInfoItem(
            icon: PhosphorIcons.mapPin(),
            label: _surah!.revelationPlace.tr,
            value: "",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.premiumGold, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildAyahCard(Verse verse) {
    final isBookmarked = _bookmarks.containsKey(
      '${widget.surahNumber}:${verse.number}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: verse.sajda
            ? AppTheme.sageGreen.withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              verse.sajda ? AppTheme.sageGreen : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayet Numarası ve Aksiyonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      "Ayet ${verse.number}",
                      style: GoogleFonts.outfit(
                        color: AppTheme.premiumGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (verse.sajda) ...[
                      const SizedBox(width: 8),
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        color: AppTheme.sageGreen,
                        size: 14,
                      ),
                      Text(
                        " Secde",
                        style: GoogleFonts.outfit(
                          color: AppTheme.sageGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  // Kopyala
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.copy(),
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: "${verse.text.ar}\n\n${verse.text.en}",
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("common.copied_verse".tr())),
                      );
                    },
                  ),
                  // Paylaş
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.shareFat(),
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      final currentLang = ref.read(settingsProvider).language;
                      final meal = currentLang == 'tr' ? (verse.text.tr ?? verse.text.en) : verse.text.en;
                      Share.share(
                        "${verse.text.ar}\n\n$meal\n\n${_surah!.name.transliteration}, Ayet ${verse.number}",
                      );
                    },
                  ),
                  // Yer İmi
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? PhosphorIcons.bookmarkSimple(
                              PhosphorIconsStyle.fill,
                            )
                          : PhosphorIcons.bookmarkSimple(),
                      color: isBookmarked ? AppTheme.sageGreen : Colors.white54,
                      size: 20,
                    ),
                    onPressed: () async {
                      if (isBookmarked) {
                        await _quranService.removeBookmark(
                          widget.surahNumber,
                          verse.number,
                        );
                        setState(() {
                          _bookmarks.remove(
                            '${widget.surahNumber}:${verse.number}',
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("common.bookmark_removed".tr()),
                          ),
                        );
                      } else {
                        await _quranService.addBookmark(
                          widget.surahNumber,
                          verse.number,
                        );
                        setState(() {
                          _bookmarks['${widget.surahNumber}:${verse.number}'] =
                              true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Yer imi eklendi")),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Arapça Metin
          Text(
            verse.text.ar,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontSize: _fontSize,
              height: 2.0,
            ),
          ),

          // Meal (göster/gizle)
          if (_showMeal) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 20),
            Text(
              ref.watch(settingsProvider).language == 'tr' ? (verse.text.tr ?? verse.text.en) : verse.text.en,
              textAlign: TextAlign.left,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],

          // Cüz ve Sayfa Bilgisi
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaChip("Cüz ${verse.juz}"),
              const SizedBox(width: 8),
              _buildMetaChip("Sayfa ${verse.page}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white38,
          fontSize: 10,
        ),
      ),
    );
  }
}
