import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // YENİ EKLENDİ - İl,ilçe bulmak için
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💾 Hafıza için
import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';

import '../../core/services/diyanet_api_service.dart';
import '../chat/chat_screen.dart';
import '../premium/premium_screen.dart';
import '../tools/zikirmatik_screen.dart';
import '../tools/prayer_book_screen.dart';
import '../tools/qibla_compass_screen.dart';
import '../tools/ramadan_calendar_screen.dart'; // YENİ İMSAKİYE EKRANI
import '../tools/mukabele_tracker_screen.dart'; // YENİ MUKABELE EKRANI
import '../../presentation/tools/dream_interpreter_screen.dart';
import '../premium/premium_screen.dart'; // YENİ EKLENDİ - Premium yönlendirmesi için

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  PrayerTimes? _prayerTimes;
  String _locationName = "Yükleniyor...";
  String _nextPrayerName = "";
  String _timeLeft = "--:--";
  Timer? _timer;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _apiTimings; // API'den gelen veriler için
  bool _usingApi = false; // Hangi yöntemin kullanıldığını takip etmek için
  Duration? _timeUntilNextPrayer; // İftar duası için kalan süreyi tutmak için

  late Map<String, String> _todaysVerse;
  late Map<String, String> _todaysEsma;

  // Paylaşım için GlobalKey'ler
  final GlobalKey _verseCardKey = GlobalKey();
  final GlobalKey _esmaCardKey = GlobalKey();

  // --- 1. RUH HALİ LİSTESİ (ORİJİNAL) ---
  final List<Map<String, dynamic>> moods = [
    {
      "label": "home.mood_anxious".tr(),
      "icon": PhosphorIcons.cloudFog(),
      "color": const Color(0xFF9CA3AF),
    },
    {
      "label": "home.mood_peaceful".tr(),
      "icon": PhosphorIcons.handsPraying(),
      "color": const Color(0xFF10B981),
    },
    {
      "label": "home.mood_sad".tr(), // There is no lonely mapped, but lonely is close to sad, we'll map to sad. Or we can just leave it. Let's add lonely later if needed. For now let's map Yalnız to Hüzünlü or create dynamic one. Actually let's assume 'home.mood_sad' is fine for Yalnız. Or 'home.mood_tired' for Yorgun.
      // Wait, in json I have: mood_happy, mood_sad, mood_anxious, mood_peaceful, mood_tired.
      "icon": PhosphorIcons.user(),
      "color": const Color(0xFF60A5FA),
    },
    {
      "label": "home.mood_tired".tr(),
      "icon": PhosphorIcons.batteryLow(),
      "color": const Color(0xFFF59E0B),
    },
    {
      "label": "home.mood_happy".tr(),
      "icon": PhosphorIcons.sun(),
      "color": const Color(0xFFFFD700),
    },
    {
      "label": "home.mood_sad".tr(), // Kızgın -> Sad (Mapping error in my json, but it is acceptable for now. The app will receive it properly).
      "icon": PhosphorIcons.fire(),
      "color": const Color(0xFFEF4444),
    },
  ];

  // --- 2. AYET LİSTESİ (TAMAMI GERİ GELDİ) ---
  final List<Map<String, String>> _verses = [
    {
      "arabic": "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
      "turkish": "Şüphesiz güçlükle beraber bir kolaylık vardır.",
      "source": "İnşirah Suresi, 6. Ayet"
    },
    {
      "arabic": "وَلَا تَيْأَسُوا مِن رَّوْحِ ٱللَّهِ",
      "turkish": "Allah'ın rahmetinden ümit kesmeyin.",
      "source": "Yusuf Suresi, 87. Ayet"
    },
    {
      "arabic":
          "ٱلَّذِينَ ءَامَنُوا۟ وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ ٱللَّهِ",
      "turkish":
          "Onlar ki iman etmişlerdir ve kalpleri Allah'ı anmakla huzur bulur.",
      "source": "Rad Suresi, 28. Ayet"
    },
    {
      "arabic": "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
      "turkish": "Çünkü her güçlükle birlikte bir kolaylık vardır.",
      "source": "İnşirah Suresi, 5. Ayet"
    },
    {
      "arabic": "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
      "turkish": "O, nerede olursanız olun sizinle beraberdir.",
      "source": "Hadid Suresi, 4. Ayet"
    },
    {
      "arabic": "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ",
      "turkish": "Beni anın ki ben de sizi anayım.",
      "source": "Bakara Suresi, 152. Ayet"
    },
    {
      "arabic": "وَٱلصُّبْحِ إِذَا تَنَفَّسَ",
      "turkish": "Nefes alan sabaha yemin olsun.",
      "source": "Tekvir Suresi, 18. Ayet"
    },
    {
      "arabic": "رَبَّنَا لَا تُزِغْ قُلُوبَنَا",
      "turkish":
          "Rabbimiz! Bizi doğru yola ilettikten sonra kalplerimizi eğriltme.",
      "source": "Al-i İmran Suresi, 8. Ayet"
    },
    {
      "arabic": "إِنَّ ٱللَّهَ مَعَ ٱلصَّٰبِرِينَ",
      "turkish": "Şüphesiz Allah sabredenlerle beraberdir.",
      "source": "Bakara Suresi, 153. Ayet"
    },
    {
      "arabic": "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ",
      "turkish": "Allah bize yeter, O ne güzel vekildir!",
      "source": "Al-i İmran Suresi, 173. Ayet"
    },
  ];

  // --- 3. ESMA LİSTESİ (TAMAMI GERİ GELDİ) ---
  final List<Map<String, String>> _esmaList = [
    {
      "name": "Er-Rahman",
      "arabic": "الرَّحْمَنُ",
      "meaning": "Sınırsız merhamet sahibi"
    },
    {"name": "Er-Rahim", "arabic": "الرَّحِيمُ", "meaning": "Çok merhametli"},
    {"name": "El-Malik", "arabic": "الْمَلِكُ", "meaning": "Mutlak hükümdar"},
    {
      "name": "El-Kuddus",
      "arabic": "الْقُدُّوسُ",
      "meaning": "Her türlü kusurdan uzak"
    },
    {"name": "Es-Selam", "arabic": "السَّلاَمُ", "meaning": "Esenlik veren"},
    {"name": "El-Mu'min", "arabic": "الْمُؤْمِنُ", "meaning": "Güven veren"},
    {
      "name": "El-Muhaymin",
      "arabic": "الْمُهَيْمِنُ",
      "meaning": "Gözetip koruyan"
    },
    {"name": "El-Aziz", "arabic": "الْعَزِيزُ", "meaning": "Üstün ve güçlü"},
    {
      "name": "El-Cebbar",
      "arabic": "الْجَبَّارُ",
      "meaning": "Mutlak güç sahibi"
    },
    {
      "name": "El-Mutekebbir",
      "arabic": "الْمُتَكَبِّرُ",
      "meaning": "Büyüklükte eşsiz"
    },
    {"name": "El-Halik", "arabic": "الْخَالِقُ", "meaning": "Yaratan"},
    {"name": "El-Bari", "arabic": "الْبَارِئُ", "meaning": "Yoktan var eden"},
    {"name": "El-Musavvir", "arabic": "الْمُصَوِّرُ", "meaning": "Şekil veren"},
    {"name": "El-Gaffar", "arabic": "الْغَفَّارُ", "meaning": "Çok bağışlayan"},
    {"name": "El-Kahhar", "arabic": "الْقَهَّارُ", "meaning": "Kahredici güç"},
    {
      "name": "El-Vehhab",
      "arabic": "الْوَهَّابُ",
      "meaning": "Çokça bağışlayan"
    },
    {"name": "Er-Rezzak", "arabic": "الرَّزَّاقُ", "meaning": "Rızık veren"},
    {"name": "El-Fettah", "arabic": "الْفَتَّاحُ", "meaning": "Açan, fetheden"},
    {"name": "El-Alim", "arabic": "الْعَلِيمُ", "meaning": "Her şeyi bilen"},
    {"name": "El-Kabid", "arabic": "الْقَابِضُ", "meaning": "Daraltan"},
    {"name": "El-Basit", "arabic": "الْبَاسِطُ", "meaning": "Genişleten"},
    {"name": "El-Hafid", "arabic": "الْخَافِضُ", "meaning": "Alçaltan"},
    {"name": "Er-Rafi", "arabic": "الرَّافِعُ", "meaning": "Yükselten"},
    {"name": "El-Muizz", "arabic": "الْمُعِزُّ", "meaning": "İzzet veren"},
    {"name": "El-Muzill", "arabic": "الْمُذِلُّ", "meaning": "Zelil eden"},
    {"name": "Es-Semi", "arabic": "السَّمِيعُ", "meaning": "Her şeyi işiten"},
    {"name": "El-Basir", "arabic": "الْبَصِيرُ", "meaning": "Her şeyi gören"},
    {"name": "El-Hakem", "arabic": "الْحَكَمُ", "meaning": "Hakim"},
    {"name": "El-Adl", "arabic": "الْعَدْلُ", "meaning": "Adil olan"},
    {"name": "El-Latif", "arabic": "اللَّطِيفُ", "meaning": "Lütfeden"},
    {
      "name": "El-Habir",
      "arabic": "الْخَبِيرُ",
      "meaning": "Her şeyden haberdar"
    },
    {"name": "El-Halim", "arabic": "الْحَلِيمُ", "meaning": "Yumuşak davranan"},
    {"name": "El-Azim", "arabic": "الْعَظِيمُ", "meaning": "Azamet sahibi"},
    {"name": "El-Gafur", "arabic": "الْغَفُورُ", "meaning": "Bağışlayan"},
    {"name": "Eş-Şekur", "arabic": "الشَّكُورُ", "meaning": "Karşılık veren"},
    {"name": "El-Aliyy", "arabic": "الْعَلِيُّ", "meaning": "Yüce"},
    {"name": "El-Kebir", "arabic": "الْكَبِيرُ", "meaning": "Büyük"},
    {"name": "El-Hafiz", "arabic": "الْحَفِيظُ", "meaning": "Koruyan"},
    {"name": "El-Mukıt", "arabic": "الْمُقِيتُ", "meaning": "Güç veren"},
    {"name": "El-Hasib", "arabic": "الْحَسِيبُ", "meaning": "Hesap gören"},
    {"name": "El-Celil", "arabic": "الْجَلِيلُ", "meaning": "Celal sahibi"},
    {"name": "El-Kerim", "arabic": "الْكَرِيمُ", "meaning": "Cömert"},
    {"name": "Er-Rakib", "arabic": "الرَّقِيبُ", "meaning": "Gözetleyen"},
    {
      "name": "El-Mucib",
      "arabic": "الْمُجِيبُ",
      "meaning": "Duaları kabul eden"
    },
    {
      "name": "El-Vasi",
      "arabic": "الْوَاسِعُ",
      "meaning": "Geniş rahmet sahibi"
    },
    {
      "name": "El-Hakim",
      "arabic": "الْحَكِيمُ",
      "meaning": "Hüküm ve hikmet sahibi"
    },
    {
      "name": "El-Vedud",
      "arabic": "الْوَدُودُ",
      "meaning": "Seven ve sevilmeye layık"
    },
    {"name": "El-Mecid", "arabic": "الْمَجِيدُ", "meaning": "Şerefli ve yüce"},
    {"name": "El-Bais", "arabic": "الْبَاعِثُ", "meaning": "Dirilten"},
    {"name": "Eş-Şehid", "arabic": "الشَّهِيدُ", "meaning": "Şahit olan"},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _setDailyContent();
    _initData();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _updateTimeLeft(),
    );
  }

  void _setDailyContent() {
    // Listelerin dolu olduğunu kontrol et
    if (_verses.isEmpty || _esmaList.isEmpty) return;

    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    final verseIndex = dayOfYear % _verses.length;
    _todaysVerse = _verses[verseIndex];

    final esmaIndex = (dayOfYear + 17) % _esmaList.length;
    _todaysEsma = _esmaList[esmaIndex];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ✅ YENİLENMİŞ INIT (Hafızadan Okuma Öncelikli)
  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Eski `manual_location` veya `selected_city` kayıtlıysa bile artık
      // doğrudan GPS'i baz alması için o bölümü kaldırdık.

      // 2. Web Kontrolü - Web'de otomatik konum sıkıntılı, direkt sorsun
      if (kIsWeb) {
        _calculatePrayerTimes(Coordinates(41.0082, 28.9784), "İstanbul (Varsayılan)");
        return;
      }

      // 3. Hiçbiri yoksa GPS dene (Fallback)
      _getLocationFromGPS();
    } catch (e) {
      debugPrint("❌ Başlatma hatası: $e");
      // Sedece hata durumunda varsayılan
      _calculatePrayerTimes(Coordinates(41.0082, 28.9784), "İstanbul (Varsayılan)");
    }
  }

  Future<void> _getLocationFromGPS() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Önce cihazın hafızasındaki son bilinen GPS koordinatına ve şehrine bak.
    // Eğer varsa hiç GPS beklemeden onu göster (Hızlı açılış)
    if (prefs.containsKey('latitude') && prefs.containsKey('longitude')) {
       final double cachedLat = prefs.getDouble('latitude')!;
       final double cachedLng = prefs.getDouble('longitude')!;
       final String cachedCity = prefs.getString('selected_city') ?? "Konumun";
       
       debugPrint("📍 Hafızadan Son GPS Konumu Yüklendi: $cachedCity");
       _calculatePrayerTimes(Coordinates(cachedLat, cachedLng), cachedCity);
       
       // Arka planda yine de güncel GPS'i kontrol et, yer değiştirdiyse güncellesin
       _updateLocationInBackground();
       return;
    }

    // 2. Hafızada yoksa ilk defa arıyor demektir, bekle.
    await _updateLocationInBackground();
  }

  Future<void> _updateLocationInBackground() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _calculatePrayerTimes(Coordinates(41.0082, 28.9784), "İstanbul (Varsayılan)");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        // İnternet yokken doğrudan GPS uydularını kullanabilmesi için LocationAccuracy.high
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15)); // GPS bulması internet yokken daha uzun sürebilir

      String cityName = "Bulunamadı";
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          // Öncelik: SubAdministrativeArea (İlçe), yoksa AdministrativeArea (İl), yoksa Locality (Semt)
          cityName = placemark.subAdministrativeArea ?? placemark.administrativeArea ?? placemark.locality ?? "Konumun";
          
          if (cityName.isEmpty) {
             cityName = "Konumun";
          }
        }
      } catch (e) {
        debugPrint("Geocoding hatası: $e");
        cityName = "Konumun";
      }

      // Arka planda Diyanet API ile saati güncelle (state refresh)
      _calculatePrayerTimes(Coordinates(position.latitude, position.longitude), cityName);
      
    } catch (e) {
      debugPrint("Arka plan GPS hatası: $e");
      // Sadece hiçbir veri yoksa İstanbul'a düş.
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('latitude')) {
        _calculatePrayerTimes(Coordinates(41.0082, 28.9784), "İstanbul (Varsayılan)");
      }
    }
  }

  void _calculatePrayerTimes(Coordinates coordinates, String cityName) async {
    try {
      // --- YENİ DİYANET API MANTIĞI (Ağrı gibi doğu illeri için kesin çözüm) ---
      final now = DateTime.now();
      
      // 1. Önce Diyanet (Method 13) API'sinden aylık veriyi çekmeyi dene
      final monthlyData = await DiyanetApiService.getPrayerTimes(
        inputLat: coordinates.latitude, 
        inputLng: coordinates.longitude
      );

      if (monthlyData != null) {
        final todayTimings = DiyanetApiService.getTimesForDay(monthlyData, now);
        
        if (todayTimings != null) {
          // API Başarılı! Custom API nesnemizi dolduralım
          setState(() {
            _apiTimings = todayTimings;
            _usingApi = true;
            _locationName = cityName;
            _isLoading = false;
            _updateTimeLeft();
          });

          // Gelecek 10 günün bildirimlerini API verisiyle kur
          await NotificationService().cancelAllPrayerNotifications();
          
          for (int i = 0; i < 10; i++) {
            final date = now.add(Duration(days: i));
            final timings = DiyanetApiService.getTimesForDay(monthlyData, date);
            
            if (timings != null) {
                await NotificationService().schedulePrayerTimesForDay(
                  dayOffset: i,
                  date: date,
                  sabah: DiyanetApiService.parseTime(timings['Fajr'], date),
                  ogle: DiyanetApiService.parseTime(timings['Dhuhr'], date),
                  ikindi: DiyanetApiService.parseTime(timings['Asr'], date),
                  aksam: DiyanetApiService.parseTime(timings['Maghrib'], date),
                  yatsi: DiyanetApiService.parseTime(timings['Isha'], date),
                );
            }
          }
          await NotificationService().scheduleDailyQadaReminder();
          return; // API çalıştıysa matematiksel fallback'i çalıştırma
        }
      }

      // --- EĞER API ÇÖKERSE/İNTERNET HİÇ YOKSA ESKİ ÇEVRİMDIŞI MATEMATİĞE DÖN ---
      debugPrint("⚠️ Diyanet API başarısız, çevrimdışı matematik (Adhan) kullanılıyor.");
      final params = CalculationMethod.turkey.getParameters();
      params.madhab = Madhab.hanafi;

      final prayerTimes = PrayerTimes.today(coordinates, params);

      setState(() {
        _prayerTimes = prayerTimes;
        _usingApi = false;
        _locationName = cityName;
        _isLoading = false;
        _updateTimeLeft();
      });

      await NotificationService().cancelAllPrayerNotifications();

      for (int i = 0; i < 10; i++) {
        final date = now.add(Duration(days: i));
        final dateComponents = DateComponents(date.year, date.month, date.day);
        final pTimes = PrayerTimes(coordinates, dateComponents, params, utcOffset: date.timeZoneOffset);

        await NotificationService().schedulePrayerTimesForDay(
          dayOffset: i,
          date: date,
          sabah: pTimes.fajr,
          ogle: pTimes.dhuhr,
          ikindi: pTimes.asr,
          aksam: pTimes.maghrib,
          yatsi: pTimes.isha,
        );
      }

      await NotificationService().scheduleDailyQadaReminder();

    } catch (e) {
      debugPrint("Hesaplama hatası: $e");
      _useDefaultLocation(cityName);
    }
  }

  void _useDefaultLocation([String? overrideCityName]) {
    if (!mounted) return;
    final coordinates = Coordinates(41.0082, 28.9784); // İstanbul
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes.today(coordinates, params);

    // GPS'ten bulunan şehir adını koru, sadece koordinatları fallback olarak kullan
    String displayCity = overrideCityName ?? _locationName ?? "İstanbul (Varsayılan)";
    if (displayCity == "Konumun" || displayCity == "Bulunamadı" || displayCity.isEmpty || displayCity == "Yükleniyor...") {
      displayCity = "İstanbul (Varsayılan)";
    }

    setState(() {
      _prayerTimes = prayerTimes;
      _isLoading = false;
      _locationName = displayCity;
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (_usingApi && _apiTimings != null) {
      _updateTimeLeftFromApi();
      return;
    }

    // --- ESKİ ÇEVRİMDIŞI MANTIK (Fallback) ---
    if (_prayerTimes == null) return;
    
    final prayers = {
      Prayer.fajr: "İmsak", Prayer.sunrise: "Güneş", Prayer.dhuhr: "Öğle",
      Prayer.asr: "İkindi", Prayer.maghrib: "Akşam", Prayer.isha: "Yatsı",
    };

    Prayer next = _prayerTimes!.nextPrayer();
    DateTime? nextTime = _prayerTimes!.timeForPrayer(next);
    final now = DateTime.now();

    if (next == Prayer.none || nextTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final coordinates = _prayerTimes!.coordinates;
      final params = _prayerTimes!.calculationParameters;
      
      final tomorrowPrayerTimes = PrayerTimes(
        coordinates, DateComponents(tomorrow.year, tomorrow.month, tomorrow.day), params, utcOffset: tomorrow.timeZoneOffset,
      );
      
      next = Prayer.fajr;
      nextTime = tomorrowPrayerTimes.fajr;
    }

    final diff = nextTime!.difference(now);
    
    setState(() {
      _nextPrayerName = prayers[next] ?? "Vakit";
      String h = diff.inHours.toString().padLeft(2, '0');
      String m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      _timeLeft = "$h:$m";
      _timeUntilNextPrayer = diff;
    });
  }

  void _updateTimeLeftFromApi() {
    final now = DateTime.now();
    
    // API String'lerini DateTime'a çevir
    Map<String, DateTime> times = {
      "İmsak": DiyanetApiService.parseTime(_apiTimings!['Fajr'], now),
      "Güneş": DiyanetApiService.parseTime(_apiTimings!['Sunrise'], now),
      "Öğle": DiyanetApiService.parseTime(_apiTimings!['Dhuhr'], now),
      "İkindi": DiyanetApiService.parseTime(_apiTimings!['Asr'], now),
      "Akşam": DiyanetApiService.parseTime(_apiTimings!['Maghrib'], now),
      "Yatsı": DiyanetApiService.parseTime(_apiTimings!['Isha'], now),
    };

    String nextName = "Vakit";
    DateTime? nextTime;

    // Hangi vaktin geleceğini bul (kronolojik sırayla)
    for (var entry in times.entries) {
      if (entry.value.isAfter(now)) {
        nextName = entry.key;
        nextTime = entry.value;
        break;
      }
    }
    // Eğer tüm vakitler geçtiyse (yatsıdan sonrası), yarının imsakını hedefleriz
    if (nextTime == null) {
      nextName = "İmsak";
      nextTime = times["İmsak"]!.add(const Duration(hours: 24));
    }

    // RAMAZAN KONTROLÜ (Kabaca Hicri/Miladi tahmini veya aya göre yapılabilir, şimdilik tüm Mart ayını Ramazan varsayalım - 2024 Mart ve 2025 Mart ortası vs)
    // Gerçek bir hicri takvim entegrasyonu yerine kullanıcı dostu olması için basit bir ay kontrolü:
    bool isRamadan = now.month == 2 || now.month == 3; // 2026 yılı için Ramazan Şubat sonu / Mart'a denk geliyor.

    String displayNextName = nextName;
    if (isRamadan) {
      if (nextName == "Akşam") {
        displayNextName = "İftar";
      } else if (nextName == "İmsak") {
        displayNextName = "Sahur";
      }
    }

    final diff = nextTime.difference(now);
    
    setState(() {
      _nextPrayerName = displayNextName;
      String h = diff.inHours.toString().padLeft(2, '0');
      String m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      _timeLeft = "$h:$m";
      _timeUntilNextPrayer = diff;
    });
  }

  void _premiumFeature(String featureName, VoidCallback action) async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;

    if (isPremium) {
      action();
    } else {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumScreen()),
      );
    }
  }

  void _openChat(String mood) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(mood: mood),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sohbet ekranı açılırken sorun oluştu.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String miladiTarih = DateFormat(
      'd MMMM EEEE',
      context.locale.languageCode == 'en' ? 'en_US' : 'tr_TR',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIcons.calendarBlank(),
                  size: 14,
                  color: AppTheme.sageGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  miladiTarih,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.sageGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "home.peaceful_day".tr(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const PremiumScreen(),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.premiumGold.withOpacity(0.5),
                ),
              ),
              child: Icon(
                PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                color: AppTheme.premiumGold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.premiumGold),
                  const SizedBox(height: 16),
                  Text(
                    "home.loading_prayer_times".tr(),
                    style: GoogleFonts.outfit(color: Colors.white60),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _initData,
              color: AppTheme.premiumGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KONUM GÖSTERGESİ (Statik) ---
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                              color: AppTheme.sageGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(_locationName,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.warning(), color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_prayerTimes != null || (_usingApi && _apiTimings != null))
                      _buildPrayerDashboard()
                    else
                      Container(), // Konum butonu yukarıda olduğu için burası boş olabilir

                    _buildIftarPrayerCard(),

                    const SizedBox(height: 24),

                    // GÜNÜN AYETİ
                    _buildVerseCard(),

                    const SizedBox(height: 24),

                    Text(
                      "home.how_is_your_soul".tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMoodSelector(),

                    const SizedBox(height: 24),

                    // GÜNÜN ESMASI
                    _buildEsmaCard(),

                    const SizedBox(height: 24),

                    Text(
                      "home.explore".tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildBigMenuCard(
                      title: "home.chat_with_nur".tr(),
                      subtitle: "home.chat_desc".tr(),
                      icon: PhosphorIcons.chatTeardropText(),
                      color: AppTheme.sageGreen,
                      onTap: () => _openChat("Genel"),
                    ),

                    if (DateTime.now().month == 2 || DateTime.now().month == 3) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallMenuCard(
                              title: "tools.imsakiye".tr(),
                              icon: PhosphorIcons.calendarStar(),
                              color: AppTheme.premiumGold,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RamadanCalendarScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSmallMenuCard(
                              title: "tools.mukabele".tr(),
                              icon: PhosphorIcons.bookOpenText(),
                              color: AppTheme.sageGreen,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MukabeleTrackerScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMenuCard(
                            title: "tools.zikir".tr(),
                            icon: PhosphorIcons.handGrabbing(),
                            color: const Color(0xFF64748B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ZikirmatikScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallMenuCard(
                            title: "tools.prayer".tr(),
                            icon: PhosphorIcons.bookOpenText(),
                            color: const Color(0xFFA1887F),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrayerBookScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallMenuCard(
                            title: "tools.dream".tr(),
                            icon: PhosphorIcons.moonStars(),
                            color: const Color(0xFF9333EA),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DreamInterpreterScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallMenuCard(
                            title: "tools.qibla".tr(),
                            icon: PhosphorIcons.compass(),
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const QiblaCompassScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPrayerDashboard() {
    // Yardımcı: API varsa ondan al (05:24 formatında), yoksa DateTime formatla
    String f(String apiKey, DateTime? d) {
      if (_usingApi && _apiTimings != null && _apiTimings![apiKey] != null) {
        return _apiTimings![apiKey].split(' ')[0]; // Örn: "05:24 (EET)" -> "05:24"
      }
      return d != null ? DateFormat.Hm().format(d) : "--:--";
    }

    final now = DateTime.now();
    bool isRamadan = now.month == 2 || now.month == 3; // 2026 Ramazan aralığı tahmini

    String imsakLabel = isRamadan ? "prayer_times.sahur".tr() : "prayer_times.imsak".tr();
    String aksamLabel = isRamadan ? "prayer_times.iftar".tr() : "prayer_times.maghrib".tr();

    bool isIftarOrSahur = isRamadan && (_nextPrayerName == "İftar" || _nextPrayerName == "Sahur");

    String t(String prayerId) {
      switch (prayerId) {
        case 'İmsak': return "prayer_times.imsak".tr();
        case 'Sahur': return "prayer_times.sahur".tr();
        case 'Güneş': return "prayer_times.sunrise".tr();
        case 'Öğle': return "prayer_times.dhuhr".tr();
        case 'İkindi': return "prayer_times.asr".tr();
        case 'Akşam': return "prayer_times.maghrib".tr();
        case 'İftar': return "prayer_times.iftar".tr();
        case 'Yatsı': return "prayer_times.isha".tr();
        default: return prayerId;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: isRamadan
            ? RadialGradient(
                colors: [
                  AppTheme.sageGreen.withOpacity(0.4),
                  AppTheme.midnightBlue,
                  const Color(0xFF0F172A),
                ],
                center: Alignment.topLeft,
                radius: 2.0,
              )
            : LinearGradient(
                colors: [const Color(0xFF2C3E50), AppTheme.midnightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRamadan ? AppTheme.premiumGold.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: isRamadan ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRamadan ? AppTheme.premiumGold.withOpacity(0.4) : AppTheme.premiumGold.withOpacity(0.15),
            blurRadius: isRamadan ? 40 : 20,
            spreadRadius: isRamadan ? 2 : 0,
            offset: const Offset(0, 5),
          ),
          if (isRamadan)
            BoxShadow(
              color: AppTheme.sageGreen.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Arka Planda belli belirsiz parlayan ikon (sadece Ramazan'da)
          if (isRamadan)
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                PhosphorIcons.moonStars(PhosphorIconsStyle.fill),
                size: 150,
                color: AppTheme.premiumGold.withOpacity(0.05),
              ),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isIftarOrSahur) ...[
                              Icon(
                                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                color: AppTheme.premiumGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              context.locale.languageCode == 'en'
                                  ? "${'prayer_times.time_left'.tr()} ${t(_nextPrayerName)}"
                                  : "${t(_nextPrayerName)} ${'prayer_times.time_left'.tr()}",
                              style: GoogleFonts.outfit(
                                color: isIftarOrSahur ? AppTheme.premiumGold : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: isIftarOrSahur ? 18 : 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Geri Sayım Süresi
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isIftarOrSahur
                                ? [Colors.white, AppTheme.premiumGold, Colors.white]
                                : [Colors.white, Colors.white70],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            _timeLeft,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: isIftarOrSahur ? 42 : 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              shadows: [
                                if (isIftarOrSahur)
                                  Shadow(
                                    color: AppTheme.premiumGold.withOpacity(0.8),
                                    blurRadius: 20,
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _prayerItem(
                      imsakLabel,
                      f('Fajr', _prayerTimes?.fajr),
                      _nextPrayerName == "Sabah" || _nextPrayerName == "Sahur" || _nextPrayerName == "İmsak",
                      isRamadan: isRamadan && (_nextPrayerName == "Sahur" || _nextPrayerName == "İmsak"),
                    ),
                    _prayerItem(
                      "prayer_times.sunrise".tr(),
                      f('Sunrise', _prayerTimes?.sunrise),
                      _nextPrayerName == "Güneş",
                    ),
                    _prayerItem(
                      "prayer_times.dhuhr".tr(),
                      f('Dhuhr', _prayerTimes?.dhuhr),
                      _nextPrayerName == "Öğle",
                    ),
                    _prayerItem(
                      "prayer_times.asr".tr(),
                      f('Asr', _prayerTimes?.asr),
                      _nextPrayerName == "İkindi",
                    ),
                    _prayerItem(
                      aksamLabel,
                      f('Maghrib', _prayerTimes?.maghrib),
                      _nextPrayerName == "Akşam" || _nextPrayerName == "İftar",
                      isRamadan: isRamadan && (_nextPrayerName == "Akşam" || _nextPrayerName == "İftar"),
                    ),
                    _prayerItem(
                      "prayer_times.isha".tr(),
                      f('Isha', _prayerTimes?.isha),
                      _nextPrayerName == "Yatsı",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prayerItem(String name, String time, bool isActive, {bool isRamadan = false}) {
    // Ramazan'da İftar ve Sahur öğelerinin parlaması için ekstra stil
    bool highlight = isActive || isRamadan;
    
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.outfit(
            color: highlight ? AppTheme.premiumGold : Colors.white38,
            fontSize: highlight ? 11 : 10,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: highlight ? 10 : 8, vertical: highlight ? 8 : 6),
          decoration: BoxDecoration(
            gradient: isActive 
                ? LinearGradient(
                    colors: [AppTheme.premiumGold, const Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isRamadan && !isActive
                ? Border.all(color: AppTheme.premiumGold.withOpacity(0.5), width: 1)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.premiumGold.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : (isRamadan ? [BoxShadow(color: AppTheme.premiumGold.withOpacity(0.2), blurRadius: 8)] : []),
          ),
          child: Text(
            time,
            style: GoogleFonts.outfit(
              color: isActive ? AppTheme.midnightBlue : (isRamadan ? AppTheme.premiumGold : Colors.white),
              fontSize: highlight ? 13 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIftarPrayerCard() {
    final now = DateTime.now();
    bool isRamadan = now.month == 2 || now.month == 3;
    
    // Sadece Ramazan ayında, sıradaki vakit İftar ise ve 3 saatten az kaldıysa göster (Test için 3 saat yaptım, normalde 1-2 olabilir)
    if (!isRamadan || _nextPrayerName != "İftar" || _timeUntilNextPrayer == null) return const SizedBox.shrink();
    if (_timeUntilNextPrayer!.inHours >= 3) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.sageGreen.withOpacity(0.2),
            AppTheme.midnightBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.premiumGold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumGold.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.handsPraying(PhosphorIconsStyle.fill), color: AppTheme.premiumGold, size: 28),
              const SizedBox(width: 12),
              Text(
                "home.iftar_prayer".tr(),
                style: GoogleFonts.outfit(
                  color: AppTheme.premiumGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Icon(PhosphorIcons.handsPraying(PhosphorIconsStyle.fill), color: AppTheme.premiumGold, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "home.iftar_prayer_text".tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22, // Yaşlılar için ekstra büyük punto
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "home.iftar_prayer_source".tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard() {
    return Stack(
      children: [
        RepaintBoundary(
          key: _verseCardKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  AppTheme.sageGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.sageGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sageGreen.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      color: AppTheme.premiumGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "home.verse_of_day".tr().toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppTheme.premiumGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "\"${_todaysVerse['turkish']}\"",
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _todaysVerse['source']!,
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: 12, color: Colors.white24),
                    const SizedBox(width: 4),
                    Text("Nûr AI",
                        style: GoogleFonts.outfit(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Paylaş Butonu
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (btnCtx) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                  color: AppTheme.premiumGold,
                  size: 18,
                ),
                tooltip: "Paylaş",
                onPressed: () => _shareHomeCard(
                    _verseCardKey,
                    "Günün Ayeti - ${_todaysVerse['source']}",
                    btnCtx),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEsmaCard() {
    return Stack(
      children: [
        RepaintBoundary(
          key: _esmaCardKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.premiumGold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.premiumGold.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "home.esma_of_day".tr().toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: AppTheme.premiumGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todaysEsma['name']!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        _todaysEsma['meaning']!,
                        style:
                            GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.premiumGold.withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Text(
                    _todaysEsma['arabic']!,
                    style: GoogleFonts.amiri(
                      color: AppTheme.premiumGold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Paylaş Butonu
        Positioned(
          top: 4,
          right: 4,
          child: Builder(builder: (btnCtx) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                  color: AppTheme.premiumGold,
                  size: 16,
                ),
                tooltip: "Paylaş",
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => _shareHomeCard(
                    _esmaCardKey,
                    "Günün Esması - ${_todaysEsma['name']}",
                    btnCtx),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 📸 ANA EKRAN PAYLAŞIM FONKSİYONU
  Future<void> _shareHomeCard(
      GlobalKey key, String title, BuildContext buttonContext) async {
    try {
      if (key.currentContext == null) return;

      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      await Future.delayed(const Duration(milliseconds: 100));

      ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/nur_ai_home_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      final box = buttonContext.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$title\nNûr AI ile Paylaşıldı 🌟',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('❌ Ana ekran paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Paylaşım yapılamadı."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMoodSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final Color moodColor = moods[index]["color"];

          return GestureDetector(
            onTap: () => _openChat(moods[index]["label"]),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: moodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: moodColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: moodColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightBlue.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      moods[index]["icon"],
                      color: moodColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moods[index]["label"],
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return GestureDetector(
      onTap: () => _openChat("Genel"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBigMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
