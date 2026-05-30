import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ
import '../../core/theme/app_theme.dart';
import '../../core/services/diyanet_api_service.dart';

class RamadanCalendarScreen extends StatefulWidget {
  const RamadanCalendarScreen({super.key});

  @override
  State<RamadanCalendarScreen> createState() => _RamadanCalendarScreenState();
}

class _RamadanCalendarScreenState extends State<RamadanCalendarScreen> {
  List<dynamic>? _monthlyData;
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double lat = 41.0082; // Default İstanbul
      double lng = 28.9784;

      if (prefs.containsKey('latitude') && prefs.containsKey('longitude')) {
        lat = prefs.getDouble('latitude')!;
        lng = prefs.getDouble('longitude')!;
      } else {
        // GPS izni kontrolü (basit)
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }

      final data = await DiyanetApiService.getPrayerTimes(inputLat: lat, inputLng: lng);
      
      if (mounted) {
        setState(() {
          _monthlyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ramadan_calendar.error_fetch".tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Çok koyu şık lacivert
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "ramadan_calendar.title".tr(),
          style: GoogleFonts.outfit(
            color: AppTheme.premiumGold,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.premiumGold),
            const SizedBox(height: 16),
            Text(
              "ramadan_calendar.preparing".tr(),
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _monthlyData == null || _monthlyData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage.isNotEmpty ? _errorMessage : "ramadan_calendar.no_data".tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.orange, fontSize: 18),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHeaderRow(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: _monthlyData!.length,
            itemBuilder: (context, index) {
              final dayData = _monthlyData![index];
              return _buildDayRow(dayData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.midnightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.premiumGold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _headerText("ramadan_calendar.date".tr(), flex: 2),
          _headerText("ramadan_calendar.fajr".tr(), color: AppTheme.premiumGold),
          _headerText("ramadan_calendar.dhuhr".tr()),
          _headerText("ramadan_calendar.asr".tr()),
          _headerText("ramadan_calendar.maghrib".tr(), color: AppTheme.premiumGold),
          _headerText("ramadan_calendar.isha".tr()),
        ],
      ),
    );
  }

  Widget _headerText(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: color ?? Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12, // Küçültüldü ki sığsın
        ),
      ),
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayData) {
    final timings = dayData['timings'];
    final dateObj = dayData['date']['gregorian'];
    final String dateString = dateObj['date']; // "20-02-2026"
    final String dayNumber = dateObj['day']; // "20"
    final String monthName = dateObj['month']['en']; // "February" (Basit tutalım veya sayıyla verelim)

    // Bugün mü kontrolü
    final now = DateTime.now();
    final todayString = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    final bool isToday = dateString == todayString;

    // Saatleri temizle "05:24 (EET)" -> "05:24"
    String cleanTime(String raw) => raw.split(' ')[0];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.sageGreen.withOpacity(0.2) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: AppTheme.premiumGold, width: 2) : Border.all(color: Colors.white10),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.premiumGold.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (isToday)
                  Text("ramadan_calendar.today".tr(), style: GoogleFonts.outfit(color: AppTheme.premiumGold, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(
                  "$dayNumber",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: isToday ? AppTheme.premiumGold : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isToday ? 18 : 16, // Tarih satırı puntoları düzeltildi
                  ),
                ),
              ],
            ),
          ),
          _timeText(cleanTime(timings['Fajr']), isToday, highlight: true),
          _timeText(cleanTime(timings['Dhuhr']), isToday),
          _timeText(cleanTime(timings['Asr']), isToday),
          _timeText(cleanTime(timings['Maghrib']), isToday, highlight: true),
          _timeText(cleanTime(timings['Isha']), isToday),
        ],
      ),
    );
  }

  Widget _timeText(String time, bool isToday, {bool highlight = false}) {
    return Expanded(
      flex: 1,
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: highlight ? AppTheme.premiumGold : (isToday ? Colors.white : Colors.white70),
          fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          fontSize: highlight ? 14 : 12, // İftar ve sahur büyük punto ama sığması için küçültüldü
        ),
      ),
    );
  }
}
