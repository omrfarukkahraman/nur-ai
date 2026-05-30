import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // YENİ EKLENDİ
import '../../core/theme/app_theme.dart';

class MukabeleTrackerScreen extends StatefulWidget {
  const MukabeleTrackerScreen({super.key});

  @override
  State<MukabeleTrackerScreen> createState() => _MukabeleTrackerScreenState();
}

class _MukabeleTrackerScreenState extends State<MukabeleTrackerScreen> {
  // 30 cüzün okunma durumunu tutacak liste (0 index: 1. cüz)
  List<bool> _juzStatus = List.generate(30, (index) => false);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedStatus = prefs.getStringList('mukabele_status');
    
    if (savedStatus != null && savedStatus.length == 30) {
      setState(() {
        _juzStatus = savedStatus.map((e) => e == 'true').toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleJuz(int index) async {
    setState(() {
      _juzStatus[index] = !_juzStatus[index];
    });
    
    final prefs = await SharedPreferences.getInstance();
    List<String> stringList = _juzStatus.map((e) => e.toString()).toList();
    await prefs.setStringList('mukabele_status', stringList);
  }
  
  void _resetTracker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        title: Text("mukabele.reset".tr(), style: GoogleFonts.outfit(color: Colors.white)),
        content: Text("mukabele.reset_confirm".tr(), 
            style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr(), style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() {
                _juzStatus = List.generate(30, (index) => false);
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('mukabele_status');
              if (mounted) Navigator.pop(context);
            },
            child: Text("mukabele.yes_reset".tr(), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int completedCount = _juzStatus.where((e) => e).length;
    bool isHatimComplete = completedCount == 30;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "mukabele.title".tr(),
          style: GoogleFonts.outfit(
            color: AppTheme.premiumGold,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowCounterClockwise(), color: Colors.white70),
            onPressed: _resetTracker,
            tooltip: "mukabele.reset".tr(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildProgressHeader(completedCount, isHatimComplete),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
              itemCount: 30,
              itemBuilder: (context, index) {
                return _buildJuzCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(int completedCount, bool isHatimComplete) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.midnightBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHatimComplete ? AppTheme.premiumGold : Colors.white10,
          width: isHatimComplete ? 2 : 1,
        ),
        boxShadow: isHatimComplete
            ? [BoxShadow(color: AppTheme.premiumGold.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "mukabele.read_juz".tr(),
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "$completedCount",
                      style: GoogleFonts.outfit(
                        color: AppTheme.premiumGold,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: " / 30",
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completedCount / 30,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.premiumGold),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          if (isHatimComplete) ...[
             const SizedBox(height: 16),
             Text(
               "mukabele.congrats_hatim".tr(),
               style: GoogleFonts.outfit(color: AppTheme.premiumGold, fontSize: 18, fontWeight: FontWeight.bold),
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildJuzCard(int index) {
    bool isRead = _juzStatus[index];

    return GestureDetector(
      onTap: () => _toggleJuz(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.sageGreen.withOpacity(0.15) : AppTheme.midnightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppTheme.sageGreen.withOpacity(0.5) : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRead ? AppTheme.sageGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.orbitron(
                        color: isRead ? AppTheme.premiumGold : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "${index + 1}. ${'mukabele.juz'.tr()}",
                  style: GoogleFonts.outfit(
                    color: isRead ? AppTheme.premiumGold : Colors.white,
                    fontSize: 22, // Yaşlılar için büyük punto
                    fontWeight: isRead ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead ? AppTheme.sageGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRead ? AppTheme.sageGreen : Colors.white38,
                  width: 2,
                ),
              ),
              child: isRead
                  ? const Icon(Icons.check, color: Colors.white, size: 28)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
