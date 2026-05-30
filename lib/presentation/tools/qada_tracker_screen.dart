import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
// Az önce oluşturduğumuz servisi import et (yolu kontrol et)
import '../../core/services/notification_service.dart';

class QadaTrackerScreen extends StatefulWidget {
  const QadaTrackerScreen({super.key});

  @override
  State<QadaTrackerScreen> createState() => _QadaTrackerScreenState();
}

class _QadaTrackerScreenState extends State<QadaTrackerScreen> {
  bool _isReminderOn = false; // Bildirim açık mı?

  final Map<String, int> _counts = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitir": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var key in _counts.keys) {
        _counts[key] = prefs.getInt('qada_$key') ?? 0;
      }
      // Bildirim durumu kayıtlı mı?
      _isReminderOn = prefs.getBool('daily_reminder') ?? false;
    });
  }

  Future<void> _updateCount(String key, int change) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      int newValue = _counts[key]! + change;
      if (newValue < 0) newValue = 0;
      _counts[key] = newValue;
      prefs.setInt('qada_$key', newValue);
    });
  }

  Future<void> _toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderOn = value;
      prefs.setBool('daily_reminder', value);
    });

    if (value) {
      // HATA BURADAYDI: scheduleDailyNotification -> scheduleDailyQadaReminder
      await NotificationService().scheduleDailyQadaReminder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("common.reminder_set".tr()),
          ),
        );
      }
    } else {
      // Sadece Kaza Takip Bildirimini İptal Et (ID: 100)
      await NotificationService().cancelId(100);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("common.reminder_off".tr())),
        );
      }
    }
  }

  // Toplam Borç Hesaplama
  int get totalQada => _counts.values.reduce((a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Kaza Çetelesi",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Sağ üstte Bildirim İkonu
          IconButton(
            icon: Icon(
              _isReminderOn
                  ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill)
                  : PhosphorIcons.bellSlash(),
              color: _isReminderOn ? AppTheme.premiumGold : Colors.white54,
            ),
            onPressed: () => _toggleReminder(!_isReminderOn),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Ekran taşmasın diye
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. DASHBOARD (Toplam Borç Kartı) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.premiumGold, const Color(0xFFFDE047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.premiumGold.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Toplam Borç",
                        style: GoogleFonts.outfit(
                          color: AppTheme.midnightBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalQada Vakit",
                        style: GoogleFonts.outfit(
                          color: AppTheme.midnightBlue,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Dekoratif İkon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.chartPieSlice(PhosphorIconsStyle.fill),
                      color: AppTheme.midnightBlue,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. BİLDİRİM AÇMA KARTI (Eğer kapalıysa göster) ---
            if (!_isReminderOn)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.clock(), color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Düzenli takip için hatırlatıcıyı açabilirsin.",
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isReminderOn,
                      onChanged: _toggleReminder,
                      activeColor: AppTheme.premiumGold,
                    ),
                  ],
                ),
              ),

            // --- 3. LİSTE BAŞLIĞI ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Vakitler",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 4. KART LİSTESİ ---
            ..._counts.keys.map((prayer) => _buildPrayerCard(prayer)).toList(),

            // Alt Boşluk
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String prayerName) {
    int count = _counts[prayerName]!;
    bool isCompleted = count == 0; // Borç bitti mi?

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Card Rengi
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981)
              : Colors.white10, // Bitince yeşil çerçeve
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Sol İkon Kutusu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted
                  ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                  : PhosphorIcons.clock(),
              color: isCompleted ? const Color(0xFF10B981) : Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // İsim ve Alt Metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isCompleted ? "Borç Yok" : "$count vakit kaldı",
                  style: GoogleFonts.outfit(
                    color:
                        isCompleted ? const Color(0xFF10B981) : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Butonlar (Eğer borç yoksa gizle veya tebrik göster)
          if (!isCompleted)
            Row(
              children: [
                _circleButton(Icons.remove, () => _updateCount(prayerName, -1)),
                const SizedBox(width: 12),
                _circleButton(
                  Icons.add,
                  () => _updateCount(prayerName, 1),
                  isAdd: true,
                ),
              ],
            )
          else
            Icon(
              Icons.star,
              color: const Color(0xFF10B981),
              size: 20,
            ), // Tebrik yıldızı
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isAdd ? AppTheme.premiumGold : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isAdd ? Colors.transparent : Colors.white24,
          ),
        ),
        child: Icon(
          icon,
          color: isAdd ? AppTheme.midnightBlue : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
