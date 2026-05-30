import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Kopyalama işlemi için
import 'package:share_plus/share_plus.dart'; // PAYLAŞIM PAKETİ
import '../../../core/theme/app_theme.dart';

class VerseCard extends StatelessWidget {
  final String arabicText;
  final String mealText;
  final String surahName;
  final String verseNumber;

  const VerseCard({
    super.key,
    required this.arabicText,
    required this.mealText,
    required this.surahName,
    required this.verseNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.midnightBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.premiumGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumGold.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- KART BAŞLIĞI (Sure İsmi) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.premiumGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$surahName, $verseNumber. Ayet",
                      style: GoogleFonts.outfit(
                        color: AppTheme.premiumGold,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.bookmark_border,
                  color: Colors.white30,
                  size: 20,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- ARAPÇA METİN ---
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    arabicText,
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 24,
                      height: 2.0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 24),

                // --- TÜRKÇE MEAL ---
                Text(
                  mealText,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // --- ALT BUTONLAR (Paylaş / Kopyala) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Kopyala Butonu
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: "$mealText\n\n($surahName, $verseNumber)",
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("common.copied_verse".tr())),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                ),
                const SizedBox(width: 8),

                // Hikayede Paylaş Butonu (Görsel Şölen)
                GestureDetector(
                  onTap: () {
                    // --- PAYLAŞ BUTONU AKTİF ---
                    final String shareText =
                        """
$surahName, $verseNumber. Ayet

"$mealText"

Nûr AI ile gönderildi.
""";
                    Share.share(shareText);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.premiumGold,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.share,
                          size: 16,
                          color: AppTheme.midnightBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Paylaş",
                          style: GoogleFonts.outfit(
                            color: AppTheme.midnightBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
