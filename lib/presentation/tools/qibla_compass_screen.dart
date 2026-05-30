import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double? _currentHeading; // Pusula yönü (0-360)
  double? _qiblaDirection; // Kıble yönü (hesaplanacak)
  bool _isLoading = true;
  String? _errorMessage;
  String _locationInfo = "Konum alınıyor...";

  // 🕋 KABE KOORDİNATLARI
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  Future<void> _initCompass() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1️⃣ KONUM İZNİ AL
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Konum izni gerekli');
      }

      // 2️⃣ KONUMU AL
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Konum alınamadı'),
      );

      // 3️⃣ KIBLE YÖNÜNÜ HESAPLA
      double qibla = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _qiblaDirection = qibla;
        _locationInfo =
            "Konum: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        _isLoading = false;
      });

      // 4️⃣ PUSULA SENSÖRÜNÜ DİNLE
      FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) {
          setState(() {
            _currentHeading = event.heading;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // 📐 KIBLE YÖNÜ HESAPLAMA (Haversine Formülü)
  double _calculateQiblaDirection(double lat, double lng) {
    // Radyan'a çevir
    double latRad = _toRadians(lat);
    double lngRad = _toRadians(lng);
    double kaabaLatRad = _toRadians(kaabaLat);
    double kaabaLngRad = _toRadians(kaabaLng);

    // Formül
    double dLng = kaabaLngRad - lngRad;
    double y = sin(dLng);
    double x = cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(dLng);

    double qibla = atan2(y, x);
    qibla = _toDegrees(qibla);
    qibla = (qibla + 360) % 360; // 0-360 aralığına çevir

    return qibla;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
  double _toDegrees(double radians) => radians * 180 / pi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Kıble Pusulası",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.premiumGold),
                  const SizedBox(height: 16),
                  Text(
                    "Kıble yönü hesaplanıyor...",
                    style: GoogleFonts.outfit(color: Colors.white60),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.warning(PhosphorIconsStyle.fill),
                          color: Colors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Bir Sorun Oluştu",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initCompass,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Tekrar Dene"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sageGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 📍 KONUM BİLGİSİ
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.sageGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                              color: AppTheme.sageGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _locationInfo,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 🧭 PUSULA
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 🌟 GLOW EFEKTİ
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.premiumGold.withOpacity(0.3),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),

                            // 🎯 PUSULA ÇERÇEVESİ
                            AnimatedRotation(
                              turns: _currentHeading != null
                                  ? -_currentHeading! / 360
                                  : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: CompassPainter(),
                                ),
                              ),
                            ),

                            // 🕋 KIBLE OK
                            if (_qiblaDirection != null &&
                                _currentHeading != null)
                              AnimatedRotation(
                                turns:
                                    (_qiblaDirection! - _currentHeading!) / 360,
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.caretUp(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      color: AppTheme.premiumGold,
                                      size: 80,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.premiumGold,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.premiumGold
                                                .withOpacity(0.5),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "KIBLE",
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.midnightBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 🎯 MERKEZ NOKTA
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 📊 YÖN BİLGİSİ
                      if (_currentHeading != null && _qiblaDirection != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.sageGreen.withOpacity(0.2),
                                AppTheme.sageGreen.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.sageGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoCard(
                                    "Kıble Yönü",
                                    "${_qiblaDirection!.toStringAsFixed(0)}°",
                                    PhosphorIcons.compass(
                                      PhosphorIconsStyle.fill,
                                    ),
                                  ),
                                  _buildInfoCard(
                                    "Şu Anki Yön",
                                    "${_currentHeading!.toStringAsFixed(0)}°",
                                    PhosphorIcons.navigationArrow(
                                      PhosphorIconsStyle.fill,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoCard(
                                "Fark",
                                "${((_qiblaDirection! - _currentHeading!).abs() % 360).toStringAsFixed(0)}°",
                                PhosphorIcons.arrowsClockwise(
                                  PhosphorIconsStyle.fill,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // 💡 KULLANIM KILAVUZU
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.info(PhosphorIconsStyle.fill),
                                  color: AppTheme.premiumGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Nasıl Kullanılır?",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTip("Telefonunuzu düz tutun"),
                            _buildTip(
                              "Altın ok Kıble yönünü gösterir",
                            ),
                            _buildTip(
                              "Metalik cisimlerden uzak durun",
                            ),
                            _buildTip(
                                "8 şeklinde hareket ettirerek kalibre edin"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.sageGreen, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.sageGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 PUSULA ÇİZİMİ
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // YÖN İŞARETLERİ (N, E, S, W)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final colors = [Colors.red, Colors.white70, Colors.white70, Colors.white70];

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * pi / 180;
      final x = center.dx + (radius - 30) * sin(angle);
      final y = center.dy - (radius - 30) * cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: colors[i],
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // ÇİZGİLER (Her 30 derece)
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final startRadius = i % 3 == 0 ? radius - 25 : radius - 15;
      final start = Offset(
        center.dx + startRadius * sin(angle),
        center.dy - startRadius * cos(angle),
      );
      final end = Offset(
        center.dx + radius * sin(angle),
        center.dy - radius * cos(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
