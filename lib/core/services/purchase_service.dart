// lib/core/services/purchase_service.dart

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // .env dosyasından API key'i oku
  final String _apiKey = dotenv.env['REVENUECAT_API_KEY'] ?? '';

  bool isPremium = false;
  bool _isInitialized = false;

  /// RevenueCat SDK'sını başlatır
  Future<void> init() async {
    if (kIsWeb) return; // Web'de RevenueCat çalışmaz
    if (_isInitialized) {
      print("⚠️ RevenueCat zaten başlatılmış.");
      return;
    }

    if (_apiKey.isEmpty) {
      print("❌ HATA: REVENUECAT_API_KEY bulunamadı!");
      print("💡 .env dosyasına REVENUECAT_API_KEY ekleyin.");
      return;
    }

    try {
      // Production'da info seviyesi kullan
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      // SDK'yı yapılandır
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      _isInitialized = true;
      print("✅ RevenueCat başarıyla başlatıldı!");

      // İlk abonelik durumunu kontrol et
      await checkSubscriptionStatus();
    } catch (e) {
      print("❌ RevenueCat başlatma hatası: $e");
    }
  }

  /// Kullanıcının abonelik durumunu kontrol eder
  Future<void> checkSubscriptionStatus() async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      print("⚠️ RevenueCat henüz başlatılmadı.");
      return;
    }

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // "premium" entitlement'ını kontrol et
      isPremium = customerInfo.entitlements.all[AppConstants.premiumEntitlementId]?.isActive ?? false;

      // Yerel hafızaya kaydet (Offline erişim için)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsIsPremium, isPremium);

      print("📊 Premium Durumu: ${isPremium ? 'AKTİF ✅' : 'PASİF ❌'}");

      // Debug bilgileri
      if (isPremium) {
        final entitlement = customerInfo.entitlements.all[AppConstants.premiumEntitlementId];
        print("📅 Bitiş Tarihi: ${entitlement?.expirationDate}");
        print("🔄 Otomatik Yenileme: ${entitlement?.willRenew}");
      }
    } on PlatformException catch (e) {
      print("❌ Abonelik kontrol hatası: ${e.code} - ${e.message}");

      // Hata durumunda cache'den oku
      final prefs = await SharedPreferences.getInstance();
      isPremium = prefs.getBool(AppConstants.prefsIsPremium) ?? false;
      print("💾 Cache'den okunan durum: $isPremium");
    }
  }

  /// Satın alma işlemi yapar
  Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    if (!_isInitialized) {
      print("⚠️ RevenueCat henüz başlatılmadı.");
      return false;
    }

    try {
      print("🛒 Satın alma başlatılıyor: ${package.identifier}");

      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      isPremium = customerInfo.entitlements.all[AppConstants.premiumEntitlementId]?.isActive ?? false;

      // Başarılı satın almayı kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsIsPremium, isPremium);

      if (isPremium) {
        print("✅ Satın alma başarılı! Premium aktif.");
      } else {
        print("⚠️ Satın alma tamamlandı ama premium aktif değil.");
      }

      return isPremium;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);

      // Kullanıcı iptal ettiyse sessizce geç
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        print("ℹ️ Kullanıcı satın almayı iptal etti.");
        return false;
      }

      // Diğer hatalar
      print("❌ Satın alma hatası: ${e.code} - ${e.message}");

      // Detaylı hata logları
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        print("⚠️ Bu ürün zaten satın alınmış.");
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        print("⏳ Ödeme beklemede.");
      } else if (errorCode == PurchasesErrorCode.storeProblemError) {
        print("🏪 Store problemi.");
      }

      return false;
    }
  }

  /// Satın alımları geri yükler (Restore)
  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    if (!_isInitialized) {
      print("⚠️ RevenueCat henüz başlatılmadı.");
      return false;
    }

    try {
      print("🔄 Satın alımlar geri yükleniyor...");

      CustomerInfo customerInfo = await Purchases.restorePurchases();
      isPremium = customerInfo.entitlements.all[AppConstants.premiumEntitlementId]?.isActive ?? false;

      // Başarılı restore'u kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsIsPremium, isPremium);

      if (isPremium) {
        debugPrint("✅ Satın alımlar geri yüklendi! Premium aktif.");
      } else {
        debugPrint("ℹ️ Geri yükleme tamamlandı, aktif abonelik bulunamadı.");
      }

      return isPremium;
    } on PlatformException catch (e) {
      debugPrint("❌ Restore hatası: ${e.code} - ${e.message}");
      return false;
    }
  }

  /// Mevcut offering'leri ve paketleri getirir
  Future<List<Package>> getOfferings() async {
    if (kIsWeb) return [];
    if (!_isInitialized) {
      debugPrint("⚠️ RevenueCat henüz başlatılmadı.");
      return [];
    }

    try {
      debugPrint("📦 Paketler yükleniyor...");

      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        final packages = offerings.current!.availablePackages;
        debugPrint("✅ ${packages.length} paket bulundu:");

        for (var package in packages) {
          debugPrint(
              "  - ${package.identifier}: ${package.storeProduct.priceString}");
        }

        return packages;
      } else {
        debugPrint("⚠️ Hiç paket bulunamadı. RevenueCat dashboard'ı kontrol edin.");
        return [];
      }
    } on PlatformException catch (e) {
      debugPrint("❌ Paketleri getirme hatası: ${e.code} - ${e.message}");

      if (e.code == '6' || e.message?.contains('configuration') == true) {
        debugPrint("💡 RevenueCat'te offering ayarlarınızı kontrol edin.");
        debugPrint(
            "💡 'default' offering'inizin 'Current' olarak işaretli olduğundan emin olun.");
      }

      return [];
    }
  }

  /// Kullanıcının customer ID'sini döndürür
  Future<String?> getCustomerId() async {
    if (!_isInitialized) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.originalAppUserId;
    } catch (e) {
      print("❌ Customer ID alınamadı: $e");
      return null;
    }
  }

  /// SDK'nın başlatılıp başlatılmadığını kontrol eder
  bool get isInitialized => _isInitialized;
}
