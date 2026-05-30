import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class ZikirmatikScreen extends StatefulWidget {
  const ZikirmatikScreen({super.key});

  @override
  State<ZikirmatikScreen> createState() => _ZikirmatikScreenState();
}

class _ZikirmatikScreenState extends State<ZikirmatikScreen>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _target = 0;
  String _activeZikir = "Serbest Zikir";
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  // Zikir Listesi
  final List<Map<String, dynamic>> _zikirList = [
    {"name": "Serbest Zikir", "target": 0},
    {"name": "Subhanallah", "target": 33},
    {"name": "Elhamdulillah", "target": 33},
    {"name": "Allahuekber", "target": 33},
    {"name": "Estağfirullah", "target": 100},
    {"name": "La ilahe illallah", "target": 100},
    {"name": "Salavat", "target": 100},
    {"name": "Ya Fettah", "target": 489},
    {"name": "Ya Vedud", "target": 400},
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
    // Buton basma animasyonu için controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Durumu yükle (Kaldığı yerden devam etsin)
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('zikir_count') ?? 0;
      _activeZikir = prefs.getString('active_zikir_name') ?? "Serbest Zikir";
      _target = prefs.getInt('active_zikir_target') ?? 0;
    });
  }

  // Durumu kaydet
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_count', _counter);
    await prefs.setString('active_zikir_name', _activeZikir);
    await prefs.setInt('active_zikir_target', _target);
  }

  void _selectZikir(String name, int target) {
    setState(() {
      _activeZikir = name;
      _target = target;
      // Yeni zikre geçince sayacı sıfırla
      _counter = 0;
    });
    _saveState();
    HapticFeedback.selectionClick();
  }

  Future<void> _increment() async {
    // Basma animasyonunu oynat
    await _animController.forward();
    await _animController.reverse();

    setState(() {
      _counter++;
    });

    if (_target > 0) {
      // 3 Katlı Hedef Kontrolü (Örn: 33 -> 99)
      if (_counter == _target * 3) {
        // Büyük tur bitti (99)
        HapticFeedback.heavyImpact();
        _showTargetDialog(isGrandFinish: true);
      } else if (_counter % _target == 0) {
        // Ara hedef bitti (33, 66)
        HapticFeedback.mediumImpact();
        // Ara hedeflerde sadece titreşim verir, durdurmaz
      } else {
        HapticFeedback.lightImpact();
      }
    } else {
      // Hedefsiz ise sadece tıkla
      HapticFeedback.lightImpact();
    }

    _saveState();
  }

  void _showTargetDialog({bool isGrandFinish = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.sageGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGrandFinish
                    ? PhosphorIcons.trophy(PhosphorIconsStyle.fill)
                    : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: AppTheme.sageGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isGrandFinish ? "Tebrikler!" : "Hedef Tamamlandı!",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGrandFinish
                  ? "$_activeZikir için büyük tura (${_target * 3}) ulaştın. Allah kabul etsin."
                  : "$_activeZikir zikri için $_target hedefine ulaştın.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _counter = 0);
                      _saveState();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Sıfırla",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.premiumGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Devam Et",
                      style: GoogleFonts.outfit(
                        color: AppTheme.midnightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reset() async {
    setState(() {
      _counter = 0;
    });
    HapticFeedback.mediumImpact();
    _saveState();
  }

  // Halka ilerleme değerini hesapla
  double _getProgress(int ringIndex) {
    if (_target == 0) return 0.0;

    // ringIndex: 0 -> İç Halka (0-33)
    // ringIndex: 1 -> Orta Halka (34-66)
    // ringIndex: 2 -> Dış Halka (67-99)

    int start = ringIndex * _target;
    // Eğer sayaç bu halkanın başlangıcından küçükse 0
    if (_counter <= start) return 0.0;

    // İlerleme hesabı
    double progress = (_counter - start) / _target;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Zikirmatik",
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
          IconButton(
            icon: Icon(
              PhosphorIcons.arrowCounterClockwise(),
              color: Colors.white70,
            ),
            onPressed: _reset,
            tooltip: "Sayacı Sıfırla",
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ÜST ZİKİR LİSTESİ (Yatay Kaydırmalı)
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _zikirList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final zikir = _zikirList[index];
                bool isSelected = _activeZikir == zikir['name'];
                return GestureDetector(
                  onTap: () => _selectZikir(zikir['name'], zikir['target']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.premiumGold
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.premiumGold : Colors.white10,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.premiumGold.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        zikir['target'] > 0
                            ? "${zikir['name']} (${zikir['target']})"
                            : zikir['name'],
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? AppTheme.midnightBlue
                              : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // 2. MERKEZ SAYAÇ (3 KATLI HALKA)
          Stack(
            alignment: Alignment.center,
            children: [
              // Dış Hale (Glow Effect)
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.premiumGold.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // --- DIŞ HALKA (3. Tur) ---
              if (_target > 0) ...[
                // Arka plan
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
                // Dolum
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: _getProgress(2), // 67-99 arası
                    strokeWidth: 8,
                    color: AppTheme.premiumGold.withOpacity(0.6),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ],

              // --- ORTA HALKA (2. Tur) ---
              if (_target > 0) ...[
                // Arka plan
                SizedBox(
                  width: 276, // Biraz daha küçük
                  height: 276,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
                // Dolum
                SizedBox(
                  width: 276,
                  height: 276,
                  child: CircularProgressIndicator(
                    value: _getProgress(1), // 34-66 arası
                    strokeWidth: 8,
                    color: AppTheme.premiumGold.withOpacity(0.8),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ],

              // --- İÇ HALKA (1. Tur - Ana Halka) ---
              SizedBox(
                width: 252, // En içteki
                height: 252,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              if (_target > 0)
                SizedBox(
                  width: 252,
                  height: 252,
                  child: CircularProgressIndicator(
                    value: _getProgress(0), // 0-33 arası
                    strokeWidth: 10,
                    color: AppTheme.premiumGold,
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),

              // Tıklanabilir Ana Buton
              ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: _increment,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: AppTheme.midnightBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppTheme.premiumGold.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: -5,
                          offset: const Offset(0, -5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$_counter",
                          style: GoogleFonts.orbitron(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: AppTheme.premiumGold.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_target > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                // Hedef göstergesi artık dinamik
                                _counter < _target
                                    ? "1. Tur / $_target"
                                    : _counter < _target * 2
                                        ? "2. Tur / ${_target * 2}"
                                        : "3. Tur / ${_target * 3}",
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // 3. ALT BİLGİ
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                Text(
                  _activeZikir,
                  style: GoogleFonts.amiri(
                    color: AppTheme.premiumGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Dokunarak zikre devam et",
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
