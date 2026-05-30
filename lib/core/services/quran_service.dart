// lib/core/services/quran_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_data.dart';
import '../constants/app_constants.dart';
import '../constants/quran_constants.dart';

class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // Cache için
  final Map<int, QuranSurah> _surahCache = {};

  // Toplam sure sayısı
  int get totalSurahs => 114;

  // Sure yükle (cache ile)
  Future<QuranSurah> loadSurah(int surahNumber) async {
    
    // Cache'de var mı kontrol et
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    try {
      // JSON dosyasını oku
      final jsonString = await rootBundle.loadString(
        'assets/quran/surah/surah_$surahNumber.json',
      );

      final jsonData = json.decode(jsonString);
      final surahData = QuranSurah.fromJson(jsonData);

      // Cache'e kaydet
      _surahCache[surahNumber] = surahData;

      return surahData;
    } catch (e) {
      throw Exception('Sure yüklenemedi: $e');
    }
  }

  // Tüm sure listesi (basit bilgiler)
  Future<List<SurahInfo>> getAllSurahs() async {
    // Artık JSON parse etmek yerine sabitten dönüyoruz (Çok daha hızlı)
    return QuranConstants.surahList;
  }

  // Son okunan yeri kaydet
  Future<void> saveLastRead(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsLastSurah, surah);
    await prefs.setInt(AppConstants.prefsLastAyah, ayah);
  }

  // Son okunan yeri getir
  Future<Map<String, int>> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'surah': prefs.getInt(AppConstants.prefsLastSurah) ?? 1,
      'ayah': prefs.getInt(AppConstants.prefsLastAyah) ?? 1,
    };
  }

  // Yer imi ekle
  Future<void> addBookmark(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(AppConstants.prefsBookmarks) ?? [];
    final bookmark = '$surah:$ayah';

    if (!bookmarks.contains(bookmark)) {
      bookmarks.add(bookmark);
      await prefs.setStringList(AppConstants.prefsBookmarks, bookmarks);
    }
  }

  // Yer imi sil
  Future<void> removeBookmark(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(AppConstants.prefsBookmarks) ?? [];
    bookmarks.remove('$surah:$ayah');
    await prefs.setStringList(AppConstants.prefsBookmarks, bookmarks);
  }

  // Yer imi kontrol et
  Future<bool> isBookmarked(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(AppConstants.prefsBookmarks) ?? [];
    return bookmarks.contains('$surah:$ayah');
  }

  // Tüm yer imlerini getir
  Future<List<Map<String, int>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(AppConstants.prefsBookmarks) ?? [];

    return bookmarks.map((b) {
      final parts = b.split(':');
      return {
        'surah': int.parse(parts[0]),
        'ayah': int.parse(parts[1]),
      };
    }).toList();
  }
}

// Basit sure bilgisi (liste için)
class SurahInfo {
  final int number;
  final String nameAr;
  final String nameEn;
  final String? nameTr;
  final String transliteration;
  final int versesCount;
  final String revelationType;

  SurahInfo({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    this.nameTr,
    required this.transliteration,
    required this.versesCount,
    required this.revelationType,
  });
}
