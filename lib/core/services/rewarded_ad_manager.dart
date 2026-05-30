import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntp/ntp.dart'; // İnternet saati için (Hile Koruması)
import '../constants/app_constants.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;



  // --- AYARLAR ---
  static const int _maxDailyAds = AppConstants.maxDailyAds; // Günlük Maksimum Hak
  // TEST ID (Markete çıkarken kendi ID'nle değiştireceğiz)
  static const String _adUnitId = AppConstants.rewardedAdUnitId;

  // Singleton Pattern (Uygulamanın her yerinden erişim)
  static final RewardedAdManager _instance = RewardedAdManager._internal();
  factory RewardedAdManager() => _instance;
  RewardedAdManager._internal();

  // 1. Reklamı Yükle
  Future<void> loadAd() async {
    if (_isAdLoaded || _isAdShowing) {
      debugPrint('💰 Reklam zaten yüklü veya gösteriliyor');
      return;
    }

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded Ad başarıyla yüklendi!');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _setupAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Reklam yüklenemedi: ${error.message}');
          _isAdLoaded = false;
          _rewardedAd = null;

          // Hata olursa 5 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 5), () => loadAd());
        },
      ),
    );
  }

  // 2. Callback Ayarları
  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Reklam gösterildi');
        _isAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🚪 Reklam kapatıldı');
        _isAdShowing = false;
        _isAdLoaded = false;
        ad.dispose();
        _rewardedAd = null;

        // Bir sonraki için yenisini yükle
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Reklam gösterilemedi: ${error.message}');
        _isAdShowing = false;
        _isAdLoaded = false;
        ad.dispose();
        _rewardedAd = null;

        loadAd();
      },
    );
  }

  // 3. Günlük Limit Kontrolü (HİLE KORUMALI - NTP 🛡️)
  Future<bool> canWatchAd() async {
    final prefs = await SharedPreferences.getInstance();

    DateTime now;

    try {
      // İnternetten gerçek saati çek (Kullanıcı telefon saatini değiştirse bile yemez)
      now = await NTP.now();
    } catch (e) {
      debugPrint('⚠️ NTP saati alınamadı, telefon saatine bakılıyor: $e');
      // İnternet çok kötüyse mecburen telefon saatine bakıyoruz
      now = DateTime.now();
    }

    // Bugünün tarihi (Örn: 2024-12-23)
    final String today = now.toIso8601String().split('T')[0];
    final String? lastDate = prefs.getString(AppConstants.prefsLastAdDate);

    debugPrint("📅 Kontrol Edilen Tarih (Gerçek): $today");

    // Gün değiştiyse (Dün izlediyse) sayacı sıfırla
    if (lastDate != today) {
      await prefs.setString(AppConstants.prefsLastAdDate, today);
      await prefs.setInt(AppConstants.prefsDailyAdCount, 0);
      return true; // Yeni gün, hakları sıfırlandı
    }

    // Bugün kaç tane izledi?
    final int count = prefs.getInt(AppConstants.prefsDailyAdCount) ?? 0;

    // Limit kontrolü (3'ten küçükse izleyebilir)
    return count < _maxDailyAds;
  }

  // 4. Sayaç Artırma (Ödül Alınca Çalışır)
  Future<void> consumeAdTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt(AppConstants.prefsDailyAdCount) ?? 0;
    await prefs.setInt(AppConstants.prefsDailyAdCount, count + 1);
    debugPrint("📊 Bugün izlenen reklam sayısı: ${count + 1} oldu.");
  }

  // 5. Reklamı Göster
  Future<bool> showAd({
    required Function onRewarded,
    required Function onAdClosed, // bool döndürecek: ödül aldı mı?
    required Function onAdFailed,
  }) async {
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('⚠️ Reklam henüz yüklenmedi');
      onAdFailed();
      return false;
    }

    bool rewardEarned = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎉 ÖDÜL KAZANILDI! ${reward.amount} ${reward.type}');
        rewardEarned = true;
        onRewarded(); // Ödül işlemini yap
      },
    );

    // Kapanma Callback'ini güncelle
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isAdShowing = false;
        _isAdLoaded = false;
        ad.dispose();
        _rewardedAd = null;

        // Ödül durumunu UI'a bildir
        onAdClosed(rewardEarned);

        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isAdShowing = false;
        _isAdLoaded = false;
        ad.dispose();
        _rewardedAd = null;
        onAdFailed();
        loadAd();
      },
    );

    return true;
  }

  // Reklam hazır mı?
  bool get isAdReady => _isAdLoaded && _rewardedAd != null && !_isAdShowing;
}

// --- YARDIMCI FONKSİYON (UI Tarafında Kullanılan) ---
// Sohbet ekranında veya butona basınca çağıracağın fonksiyon budur.
Future<void> showRewardedAdWithFeedback({
  required BuildContext context,
  required Function(int earnedMessages) onRewardEarned,
}) async {
  final adManager = RewardedAdManager();

  // 1. ÖNCE LİMİT KONTROLÜ YAP (NTP ile) 🛑
  // İnternet saati kontrolü biraz sürebilir, o yüzden kullanıcıya bekletme hissettirmeyelim
  // ama işlem çok hızlıdır genelde.
  bool canWatch = await adManager.canWatchAd();

  if (!canWatch) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.timer_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Günlük 3 video izleme hakkınız doldu. Yarın tekrar bekleriz!'),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return; // Fonksiyonu durdur, reklam açma
  }

  // 2. REKLAM HAZIR DEĞİLSE YÜKLE VE UYAR
  if (!adManager.isAdReady) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.downloading, color: Colors.white),
              SizedBox(width: 8),
              Text('Reklam yükleniyor, lütfen bekleyin...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await adManager.loadAd();
    return;
  }

  // 3. YÜKLENİYOR DİALOGU
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Reklam açılıyor...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. REKLAMI GÖSTER
  bool rewardGiven = false;

  await adManager.showAd(
    onRewarded: () {
      rewardGiven = true;
    },
    onAdClosed: (dynamic wasRewarded) async {
      // dynamic yapıp bool'a cast ediyoruz callback yapısından
      bool isSuccess = wasRewarded is bool ? wasRewarded : false;

      // Dialog'u kapat
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (isSuccess || rewardGiven) {
        // HAKKI DÜŞ (Hafızaya kaydet)
        await adManager.consumeAdTicket();

        // ÖDÜLÜ VER
        onRewardEarned(3);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Text('🎉 Tebrikler! +3 Hak Eklendi.'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Yarıda kapattı
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Reklamı sonuna kadar izlemediniz, ödül verilmedi.'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    },
    onAdFailed: () {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bir hata oluştu, lütfen tekrar deneyin.')),
        );
      }
    },
  );
}
