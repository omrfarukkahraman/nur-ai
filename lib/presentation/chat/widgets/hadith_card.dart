import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';

class HadithCard extends StatelessWidget {
  final String arabicText;
  final String mealText;
  final String source; // Örn: Buhari, Tıb 1

  const HadithCard({
    super.key,
    required this.arabicText,
    required this.mealText,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    // Hadis Rengi: Zümrüt Yeşili
    final Color hadithColor = const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.midnightBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hadithColor.withOpacity(0.3), // Yeşil Çerçeve
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hadithColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- KART BAŞLIĞI ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: hadithColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.scroll(),
                  color: hadithColor,
                  size: 18,
                ), // Parşömen İkonu
                const SizedBox(width: 8),
                Text(
                  "Hadis-i Şerif",
                  style: GoogleFonts.outfit(
                    color: hadithColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hadithColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    source, // Kaynak (Buhari vs)
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
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
                      fontSize: 22,
                      height: 1.8,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 20),

                // --- TÜRKÇE MEAL ---
                Text(
                  mealText,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // --- ALT BUTONLAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: "$mealText\n\n($source)"),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("common.copied_hadith".tr())),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Share.share("""
Hadis-i Şerif:
"$mealText"

Kaynak: $source
(Nûr AI ile gönderildi)
""");
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hadithColor,
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
