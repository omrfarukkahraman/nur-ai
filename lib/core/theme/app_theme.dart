// Dosya: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- RENK PALETİ (Marka Kimliğimiz) ---

  // Zemin Rengi: Derin, mat bir Gece Mavisi (Sonsuzluk hissi)
  static const Color midnightBlue = Color(0xFF0F172A);

  // Vurgu Rengi: Adaçayı Yeşili (Huzur ve Doğallık)
  static const Color sageGreen = Color(0xFF81B29A);

  // Detay Rengi: Mat Altın (Premium ve Kutsal hissi)
  static const Color premiumGold = Color(0xFFD4AF37);

  // Yazı Rengi: Göz yormayan kırık beyaz
  static const Color pureWhite = Color(0xFFF8FAFC);

  // --- TEMA AYARLARI ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: midnightBlue, // Tüm sayfalar bu renkte açılacak
      // Renk Şeması Tanımları
      colorScheme: const ColorScheme.dark(
        primary: premiumGold,
        secondary: sageGreen,
        surface: midnightBlue,
        onSurface: pureWhite,
      ),

      // Yazı Font Ayarları (Google Fonts - Outfit)
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: pureWhite,
        displayColor: pureWhite,
      ),

      // Buton Standartları (Her yerde aynı kalite)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: premiumGold, // Altın Butonlar
          foregroundColor: midnightBlue, // Üstündeki yazı koyu
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      // Kart Tasarımları (Ayet Kutuları)
      cardTheme: CardThemeData(
        color: midnightBlue.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: pureWhite.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
