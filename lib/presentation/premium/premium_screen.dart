import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    final packages = await PurchaseService().getOfferings();

    if (!mounted) return;

    setState(() {
      _packages = packages;
      _isLoading = false;
      // Varsayılan olarak yıllık paketi seç (genelde en avantajlısı)
      if (packages.isNotEmpty) {
        _selectedPackage = packages.firstWhere(
          (p) => p.packageType == PackageType.annual,
          orElse: () => packages.first,
        );
      }
    });
  }

  Future<void> _purchasePackage() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoading = true);

    final success = await PurchaseService().purchasePackage(_selectedPackage!);

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    final success = await PurchaseService().restorePurchases();

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Satın alımlarınız geri yüklendi!'
                : '❌ Aktif abonelik bulunamadı.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        Navigator.pop(context);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                color: AppTheme.premiumGold,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hoş Geldin Premium Üye! 🎉',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Artık Nûr AI\'nin tüm özelliklerinden sınırsız faydalanabilirsin!',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.premiumGold,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.pop(context); // Premium ekranını kapat
              },
              child: Text(
                'Başlayalım! 🚀',
                style: GoogleFonts.outfit(
                  color: AppTheme.midnightBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              'Geri Yükle',
              style: GoogleFonts.outfit(
                color: AppTheme.premiumGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.premiumGold,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Icon(
                    PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                    color: AppTheme.premiumGold,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nûr AI Premium',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manevi yolculuğunu sınırsız sürdür',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Özellikler
                  _buildFeature(
                    PhosphorIcons.chatCircleText(PhosphorIconsStyle.fill),
                    'Günde 50 AI Mesaj',
                    'Her gün 50 mesaj hakkı ile sınırsız sohbet',
                  ),
                  _buildFeature(
                    PhosphorIcons.moon(PhosphorIconsStyle.fill),
                    'Ayda 5 Rüya Tabiri',
                    'İslami kaynaklara göre detaylı yorumlar',
                  ),
                  _buildFeature(
                    PhosphorIcons.prohibit(PhosphorIconsStyle.fill),
                    'Reklamsız Deneyim',
                    'Kesintisiz huzurlu bir deneyim',
                  ),

                  const SizedBox(height: 32),

                  // Paketler
                  if (_packages.isNotEmpty) ...[
                    ..._packages.map((package) => _buildPackageCard(package)),
                    const SizedBox(height: 24),
                  ],

                  // Satın Al Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _selectedPackage == null ? null : _purchasePackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.premiumGold,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.premiumGold.withOpacity(0.5),
                      ),
                      child: Text(
                        'Premium\'a Geç 💎',
                        style: GoogleFonts.outfit(
                          color: AppTheme.midnightBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bilgi Metni
                  Text(
                    'İstediğin zaman iptal edebilirsin',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.premiumGold, size: 24),
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
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isSelected = _selectedPackage?.identifier == package.identifier;
    final isAnnual = package.packageType == PackageType.annual;

    // Fiyat hesaplaması
    final price = package.storeProduct.priceString;
    String? monthlyPrice;

    if (isAnnual) {
      // Yıllık paketi aylık fiyata böl
      final yearlyPrice = package.storeProduct.price;
      monthlyPrice =
          '${(yearlyPrice / 12).toStringAsFixed(2)} ${package.storeProduct.currencyCode}/ay';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.premiumGold.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.premiumGold
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.premiumGold : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.premiumGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Paket Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.storeProduct.title
                            .replaceAll('(Nur AI)', '')
                            .trim(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAnnual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            'EN AVANTAJLI',
                            style: GoogleFonts.outfit(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: GoogleFonts.outfit(
                      color: AppTheme.premiumGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (monthlyPrice != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      monthlyPrice,
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
