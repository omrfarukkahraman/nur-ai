import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class
class AppSettings {
  final String language; // 'tr' or 'en'
  
  AppSettings({this.language = 'tr'});

  AppSettings copyWith({String? language}) {
    return AppSettings(
      language: language ?? this.language,
    );
  }
}

// Notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('quran_language') ?? 'tr';
    state = state.copyWith(language: lang);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_language', lang);
    state = state.copyWith(language: lang);
  }
}

// Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
