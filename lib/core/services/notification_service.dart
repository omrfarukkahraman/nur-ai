// lib/core/services/notification_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart'; // YENİ EKLENDİ

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Web'de bildirim servisi çalışmaz
    if (kIsWeb) {
      print('⚠️ Web platformunda bildirimler devre dışı.');
      return;
    }

    // 1. Timezone Başlatma (GÜVENLİ MOD)
    try {
      tz.initializeTimeZones();
      try {
        // Cihazın yerel saat dilimini al (Örn: Europe/London)
        final String currentTimeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
        print("🌍 Cihaz Timezone: $currentTimeZone");

        final location = tz.getLocation(currentTimeZone);
        tz.setLocalLocation(location);
        print("✅ Timezone ayarlandı: $currentTimeZone");
      } catch (e) {
        // Bulamazsa varsayılan olarak İstanbul veya UTC dene
        print("⚠️ Cihaz saati bulunamadı, fallback (Istanbul) deneniyor: $e");
        try {
          final location = tz.getLocation('Europe/Istanbul');
          tz.setLocalLocation(location);
        } catch (_) {
           tz.setLocalLocation(tz.UTC);
        }
      }
    } catch (e) {
      print("🚨 Timezone veritabanı hatası: $e");
      // Kritik hata durumunda yine de UTC ayarla
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (_) {}
    }

    // 2. Platform ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Bildirime tıklandı: ${response.payload}');
      },
    );

    // 2.5 Kanalları oluştur (Ayarlarda görünmesi için)
    await _createNotificationChannels();

    // Not: İzinler init() içinde değil, UI yüklendiğinde Splash ekranında 
    // requestPermissions() çağrılarak istenir. (Android kısıtlamaları yüzünden)
  }

  // ✅ KANALLARI MANUEL OLUŞTUR (Ayarlarda görünmesi için şart)
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_channel', // ID
      'Namaz Vakitleri', // İsim
      description: 'Ezan vakti bildirimleri',
      importance: Importance.max,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('adhan_sound'), // Dosya yoksa crash verir
    );

    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'daily_reminder_channel',
      'Günlük Hatırlatıcı',
      description: 'Namaz takip hatırlatıcısı',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(prayerChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  // ✅ TÜM ANDROID VERSİYONLARI İÇİN İZİN YÖNETİMİ (11, 12, 13, 14)
  Future<void> _requestAndroidPermissions() async {
    try {
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📍 KONUM İZNİ (Android 11+ için kritik)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      // Android 11+ için önce "Uygulama kullanılırken" izni iste
      var locationStatus = await Permission.locationWhenInUse.status;

      if (locationStatus.isDenied) {
        print('📍 Konum izni isteniyor (locationWhenInUse)...');
        locationStatus = await Permission.locationWhenInUse.request();
      }

      // Hala reddedildiyse fallback: Genel location izni dene
      if (locationStatus.isDenied) {
        print('📍 Fallback: Genel konum izni deneniyor...');
        final fallbackStatus = await Permission.location.request();
        print('📍 Genel konum izni durumu: $fallbackStatus');
      } else {
        print('✅ Konum izni verildi: $locationStatus');
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🔔 BİLDİRİM İZNİ (Android 13+ için zorunlu)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      var notificationStatus = await Permission.notification.status;

      if (notificationStatus.isDenied) {
        debugPrint('🔔 Bildirim izni isteniyor (Android 13+)...');
        notificationStatus = await Permission.notification.request();
        
        // YENİ: Android 13 için Plugin üzerinden native izin talebi (Ayrıca garanti olması için)
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();

        debugPrint('🔔 Bildirim izni durumu: $notificationStatus');
      } else {
        debugPrint('✅ Bildirim izni zaten verilmiş');
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // ⏰ TAM ZAMANLI ALARM İZNİ (Android 12+ için)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      var alarmStatus = await Permission.scheduleExactAlarm.status;

      if (alarmStatus.isDenied) {
        debugPrint('⏰ Tam zamanlı alarm izni isteniyor (Android 12/14+)...');
        alarmStatus = await Permission.scheduleExactAlarm.request();
        
        // YENİ: Android 14 için Plugin üzerinden native exact alarm izin talebi
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();

        debugPrint('⏰ Alarm izni durumu: $alarmStatus');
      } else {
        debugPrint('✅ Alarm izni zaten verilmiş');
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📊 ÖZET: TÜM İZİN DURUMLARI
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      debugPrint('');
      debugPrint('═══════════════════════════════════');
      debugPrint('📊 İZİN DURUMU RAPORU:');
      debugPrint('═══════════════════════════════════');
      debugPrint('📍 Konum: ${await Permission.locationWhenInUse.status}');
      debugPrint('🔔 Bildirim: ${await Permission.notification.status}');
      debugPrint('⏰ Alarm: ${await Permission.scheduleExactAlarm.status}');
      debugPrint('═══════════════════════════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ İzin hatası: $e');
    }
  }

  // ✅ APP BAŞLANGICINDA ÇAĞRILACAK YARDIMCI METOD
  Future<void> requestPermissions() async {
     await _requestAndroidPermissions();
     await requestNotificationPermission();
  }

  // ✅ MANUEL İZİN KONTROLÜ (UI'dan çağırılabilir)
  Future<Map<String, bool>> checkAllPermissions() async {
    if (kIsWeb) {
      return {
        'location': false,
        'notification': false,
        'alarm': false,
      };
    }

    try {
      final locationStatus = await Permission.locationWhenInUse.isGranted ||
          await Permission.location.isGranted;
      final notificationStatus = await Permission.notification.isGranted;
      final alarmStatus = await Permission.scheduleExactAlarm.isGranted;

      return {
        'location': locationStatus,
        'notification': notificationStatus,
        'alarm': alarmStatus,
      };
    } catch (e) {
      print('❌ İzin kontrol hatası: $e');
      return {
        'location': false,
        'notification': false,
        'alarm': false,
      };
    }
  }

  // Manuel bildirim izni kontrolü
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Manuel konum izni kontrolü
  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return false;
    try {
      // Önce locationWhenInUse dene
      var status = await Permission.locationWhenInUse.request();
      if (status.isGranted) return true;

      // Fallback: Genel location
      status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // ✅ YENİ: Pil Optimizasyonu İsteme Fonksiyonu
  Future<void> requestBatteryOptimizationBypass() async {
    if (kIsWeb) return;
    try {
      bool? isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
      
      if (isBatteryOptimizationDisabled == false) {
        debugPrint('🔋 Pil optimizasyonu aktif! Kapatılması isteniyor...');
        await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
        debugPrint('🔋 Pil optimizasyonu ayarlarına yönlendirildi.');
      } else {
        debugPrint('✅ Pil optimizasyonu zaten devre dışı!');
      }
    } catch (e) {
      debugPrint('❌ Pil optimizasyonu kontrol hatası: $e');
    }
  }

  // NAMAZ VAKİTLERİ BİLDİRİMLERİ (Gelişmiş - Çoklu Gün)
  Future<void> schedulePrayerTimesForDay({
    required int dayOffset, // 0 = Bugün, 1 = Yarın, 2 = Ertesi gün...
    required DateTime date,
    required DateTime sabah,
    required DateTime ogle,
    required DateTime ikindi,
    required DateTime aksam,
    required DateTime yatsi,
  }) async {
    // Web'de bildirim planlanmaz
    if (kIsWeb) return;

    // Timezone kontrolü
    try {
      tz.local;
    } catch (e) {
      print("⚠️ Timezone başlatılmamış, bildirim kurulamadı.");
      return;
    }

    debugPrint('📅 Bildirimler ayarlanıyor: ${date.toString().split(' ')[0]} (Offset: $dayOffset)');

    // 🛑 AYAR KONTROLÜ: Kullanıcı bildirimleri kapatmış mı?
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!isEnabled) {
      debugPrint('🔕 Bildirimler kapalı olduğu için planlama yapılmadı.');
      return;
    }

    // 🔐 İZİN KONTROLÜ: Bildirim izni var mı?
    if (!kIsWeb) {
      final notifPermission = await Permission.notification.status;
      if (!notifPermission.isGranted) {
        debugPrint('❌ Bildirim izni verilmemiş! Planlama iptal.');
        return;
      }
    }

    // ID Mantığı:
    // Gün 0 (Bugün): 1, 2, 3, 4, 5
    // Gün 1 (Yarın): 11, 12, 13, 14, 15
    // Gün 2: 21, 22, 23, 24, 25
    int baseId = dayOffset * 10; 

    // Önce bu güne ait eski bildirimleri temizle
    for (int i = 1; i <= 5; i++) {
      await cancelId(baseId + i);
    }

    final Map<int, Map<String, dynamic>> prayers = {
      1: {
        "time": sabah,
        "title": "Sabah Namazı Vakti 🕌",
        "body": "Sabah namazı girdi. Haydi huzura..."
      },
      2: {
        "time": ogle,
        "title": "Öğle Namazı Vakti ☀️",
        "body": "Öğle ezanı okundu. İşine kısa bir ara ver."
      },
      3: {
        "time": ikindi,
        "title": "İkindi Namazı Vakti 🌤️",
        "body": "İkindi vakti girdi. Günün yorgunluğunu atma vakti."
      },
      4: {
        "time": aksam,
        "title": "Akşam Namazı Vakti 🌙",
        "body": "Akşam oldu. Evine ve Rabbine dönme vakti."
      },
      5: {
        "time": yatsi,
        "title": "Yatsı Namazı Vakti 🌌",
        "body": "Yatsı vakti. Gününü huzurla kapat."
      },
    };

    for (var entry in prayers.entries) {
      final prayerTime = entry.value["time"] as DateTime;
      
      // Sadece gelecekteki vakitleri kur
      if (prayerTime.isAfter(DateTime.now())) {
        await _scheduleSingleNotification(
          baseId + entry.key,
          entry.value["title"],
          entry.value["body"],
          prayerTime,
        );
      }
    }
  }

  // Çakışmaları önlemek için geniş aralıklı temizlik
  Future<void> cancelAllPrayerNotifications() async {
    // 10 günlük planlama yapıyoruz (Offset 0-9)
    // Her gün 5 vakit var. 
    // ID mantığı: Offset*10 + ID (Max: 90+5 = 95)
    // Güvenlik için 0-100 arasını temizleyelim.
    for (int i = 0; i < 100; i++) {
      await flutterLocalNotificationsPlugin.cancel(i);
    }
    debugPrint('🧹 Tüm namaz bildirimleri temizlendi (ID 0-99)');
  }

  // KAZA TAKİP HATIRLATICI
  Future<void> scheduleDailyQadaReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('daily_reminder') ?? false)) return;

      await cancelId(100);
      final scheduledTime = _nextInstanceOfTime(21, 00);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        100,
        'Namazlarını Kıldın mı? 🤲',
        'Bugünkü namazlarını veya kaza namazlarını kaydetmeyi unutma.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Günlük Hatırlatıcı',
            channelDescription: 'Namaz takip hatırlatıcısı',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('✅ Günlük kaza hatırlatıcısı kuruldu (21:00)');
    } catch (e) {
      debugPrint('❌ Hatırlatıcı hatası: $e');
    }
  }

  Future<void> _scheduleSingleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    try {
      if (kIsWeb) return;
      
      // Timezone'un her zaman hazır olduğundan emin ol
      try {
        tz.local; // Bu erişim başarısızsa timezone ayarlanmamış demektir
      } catch (_) {
        debugPrint('⚠️ Timezone ayarlanmamış, yeniden başlatılıyor...');
        tz.initializeTimeZones();
        try {
          final String currentTimeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
          tz.setLocalLocation(tz.getLocation(currentTimeZone));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
        }
      }

      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      debugPrint('📌 Bildirim planlanıyor - ID: $id, Saat: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}, Başlık: $title');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Namaz Vakitleri',
            channelDescription: 'Ezan vakti bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ Bildirim kuruldu - ID: $id');
    } catch (e) {
      debugPrint('❌ Bildirim kurma hatası (ID: $id): $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // Timezone güvenli erişim
    var location = tz.local;
    // Timezone safe access handled by ensuring init in main/init functions
    // The previous empty try-catch blocks were causing syntax errors and wrapping nothing.

    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // TEST BİLDİRİMİ İÇİN 5 SANİYE SONRAYA ALARM KURAR
  Future<void> scheduleTestNotification() async {
    if (kIsWeb) {
      print('⚠️ Web platformunda bildirim testi çalıştırılamaz.');
      return;
    }
    try {
      // Fallback for timezone checking mostly for debug environments missing the core init wrapper
      tz.initializeTimeZones();
      try {
        if (!tz.timeZoneDatabase.isInitialized) {
            final location = tz.getLocation('Europe/Istanbul');
            tz.setLocalLocation(location);
        }
      } catch (e) {
         print("Timezone was not initialized internally yet for tests");
      }
      
      // İzin durumunu kontrol et ve logla
      final notifPerm = await Permission.notification.status;
      final alarmPerm = await Permission.scheduleExactAlarm.status;
      debugPrint('🔐 Test öncesi izin durumu - Bildirim: $notifPerm, Alarm: $alarmPerm');

      final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      debugPrint('⏰ Test bildirimi planlanıyor: $tzDateTime');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        999, // Test ID
        '🔔 Test Bildirimi Geldi!',
        'Sistem çalışıyor, Android bildirimleri engellemiyor. Harika!',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Namaz Vakitleri',
            channelDescription: 'Ezan vakti bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ Test bildirimi 5 saniye sonraya kuruldu.');
    } catch (e) {
      print('❌ Test Bildirimi Hatası: $e');
    }
  }

  Future<void> cancelId(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
