import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class DiyanetApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/calendar';
  static const int _diyanetMethodId = 13; // Diyanet İşleri Başkanlığı

  /// Belirtilen koordinatlar için aylık namaz vakitlerini çeker ve önbelleğe alır.
  static Future<List<dynamic>?>  getPrayerTimes({double? inputLat, double? inputLng}) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    double lat = inputLat ?? prefs.getDouble('latitude') ?? 41.0082; // Varsayılan İstanbul
    double lng = inputLng ?? prefs.getDouble('longitude') ?? 28.9784;

    final cacheKey = 'prayer_times_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_${now.month}_${now.year}';

    // 1. Önbellekte var mı kontrol et (internetsiz çalışması için kritik)
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);

        
        final int cachedMonth = decoded['month'] ?? 0;
        final int cachedYear = decoded['year'] ?? 0;
        
        // Eğer veriler bu aya aitse, direkt kullan
        if (cachedMonth == now.month && cachedYear == now.year) {
          // print("✅ Namaz vakitleri önbellekten (offline) yüklendi.");
          return decoded['data'];
        }
      } catch (e) {
        // print("⚠️ Önbellek okuma hatası: $e");
      }
    }

    // 2. Önbellekte yoksa veya eskiyse internetten çek
    try {
      final url = Uri.parse('$_baseUrl/${now.year}/${now.month}?latitude=$lat&longitude=$lng&method=$_diyanetMethodId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Veriyi bu ayın numarasıyla damgalayıp kaydet
        final toCache = {
          'month': now.month,
          'year': now.year,
          'data': data['data']
        };
        await prefs.setString(cacheKey, jsonEncode(toCache));
        // print("🌐 Namaz vakitleri API'den çekildi ve kaydedildi.");
        return data['data']; // Tüm ayın listesi
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      // İnternet yoksa ama eski bir ayın önbelleği varsa son çare onu kullan (kısmi hatalı olabilir)
      if (cachedData != null) {
        return jsonDecode(cachedData)['data'];
      }
      return null;
    }
  }

  /// Verilen gün listesinden, string olarak "20-02-2026" veya bugün formatında günü bulur.
  static Map<String, dynamic>? getTimesForDay(List<dynamic> monthlyData, DateTime date) {
    final dateString = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    for (var dayData in monthlyData) {
      if (dayData['date']['gregorian']['date'] == dateString) {
        return dayData['timings'];
      }
    }
    return null; // O gün bulunamadı
  }

  /// Aladhan API'den gelen "05:24 (EET)" formatındaki stringi saf DateTime objesine dönüştürür.
  static DateTime parseTime(String timeString, DateTime currentDate) {
    final cleanTime = timeString.split(' ')[0]; // "05:24"
    final parts = cleanTime.split(':');
    return DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
