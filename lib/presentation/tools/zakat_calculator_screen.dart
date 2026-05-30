import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  // Controllers
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _debtController = TextEditingController();

  // Sabit nisap değerleri (Güncel kurlara göre ayarlanabilir, şimdilik statik)
  final double _goldNisapGrams = 80.18; // Diyanet altın nisap miktarı
  final double _goldGramPriceTRY = 2000.0; // Tahmini gram altın fiyatı (TL)
  
  double _totalWealth = 0;
  double _eligibleWealth = 0;
  double _zakatAmount = 0;
  bool _isEligible = false;

  void _calculateZakat() {
    // Girdileri al (Boşsa 0 say)
    double cash = double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0;
    double goldGrams = double.tryParse(_goldController.text.replaceAll(',', '.')) ?? 0;
    double silverWorth = double.tryParse(_silverController.text.replaceAll(',', '.')) ?? 0;
    double debts = double.tryParse(_debtController.text.replaceAll(',', '.')) ?? 0;

    // Altını TL'ye çevir
    double goldWorth = goldGrams * _goldGramPriceTRY;

    // Toplam varlık ve nisap kontrolü
    _totalWealth = cash + goldWorth + silverWorth;
    _eligibleWealth = _totalWealth - debts;

    double nisapValueTRY = _goldNisapGrams * _goldGramPriceTRY;

    setState(() {
      if (_eligibleWealth >= nisapValueTRY) {
        _isEligible = true;
        _zakatAmount = _eligibleWealth / 40.0; // %2.5 veya 1/40
      } else {
        _isEligible = false;
        _zakatAmount = 0;
      }
    });
  }

  void _clearFields() {
    _cashController.clear();
    _goldController.clear();
    _silverController.clear();
    _debtController.clear();
    setState(() {
      _totalWealth = 0;
      _eligibleWealth = 0;
      _zakatAmount = 0;
      _isEligible = false;
    });
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return format.format(amount);
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
          "Zekat Hesaplama",
          style: GoogleFonts.outfit(
            color: AppTheme.premiumGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowCounterClockwise(), color: Colors.white70),
            onPressed: _clearFields,
            tooltip: "Sıfırla",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildInputSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculateZakat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sageGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Hesapla",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildResultCard(),
            const SizedBox(height: 32), // Padding taban
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sageGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.info(PhosphorIconsStyle.fill), color: AppTheme.sageGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Diyanet'e göre zekat nisap miktarı 80.18 gram altındır. Borçlar düşüldükten sonra kalan varlığın 1/40'ı (%2.5) zekat olarak verilir.",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Varlıklarınız",
            style: GoogleFonts.outfit(
              color: AppTheme.premiumGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _cashController,
            label: "Nakit Para & Döviz",
            icon: PhosphorIcons.money(),
            suffixText: "₺",
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _goldController,
            label: "Altın",
            icon: PhosphorIcons.coins(),
            suffixText: "Gram",
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _silverController,
            label: "Gümüş & Ticari Mal Değeri",
            icon: PhosphorIcons.bank(),
            suffixText: "₺",
          ),
          const Divider(color: Colors.white24, height: 32),
          Text(
            "Borçlarınız",
            style: GoogleFonts.outfit(
              color: Colors.red[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _debtController,
            label: "Ödenecek Borçlar",
            icon: PhosphorIcons.creditCard(),
            suffixText: "₺",
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixText: suffixText,
        suffixStyle: GoogleFonts.outfit(color: AppTheme.premiumGold),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.sageGreen),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_totalWealth == 0 && _eligibleWealth == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.premiumGold.withOpacity(0.1),
            AppTheme.premiumGold.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.premiumGold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumGold.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Hesaplama Sonucu",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Zekata Tabi Varlık:", style: GoogleFonts.outfit(color: Colors.white)),
              Text(_formatCurrency(_eligibleWealth), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          if (_isEligible) ...[
            Text(
              "Vermeni Gereken Zekat Tutarı",
              style: GoogleFonts.outfit(color: AppTheme.premiumGold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(_zakatAmount),
              style: GoogleFonts.outfit(
                color: AppTheme.premiumGold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
             Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), color: Colors.orange, size: 40),
             const SizedBox(height: 12),
             Text(
              "Nisap miktarına ulaşmadığınız için zekat vermeniz şu an size farz değildir.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.orange, fontSize: 16),
            ),
          ]
        ],
      ),
    );
  }
}
