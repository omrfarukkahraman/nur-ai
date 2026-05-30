import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/purchase_service.dart';
import '../../core/services/rewarded_ad_manager.dart';
import '../premium/premium_screen.dart';
import '../widgets/banner_ad_widget.dart';

class DreamInterpreterScreen extends StatefulWidget {
  const DreamInterpreterScreen({super.key});

  @override
  State<DreamInterpreterScreen> createState() => _DreamInterpreterScreenState();
}

class _DreamInterpreterScreenState extends State<DreamInterpreterScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & Services
  final _dreamController = TextEditingController();
  final _aiService = AIService();
  final RewardedAdManager _adManager =
      RewardedAdManager(); // 👈 Reklam Yöneticisi
  late TabController _tabController;

  // State
  bool _isLoading = false;
  bool _isPremium = false;
  int _dreamLimit = 1;
  List<Map<String, dynamic>> _dreamHistory = [];

  // Sadeleştirilmiş tasarımda ekstra detaylara (his, kategori vb.) gerek yok
  // Sadece rüya metnini alacağız.


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _adManager.loadAd(); // 👈 Reklamı önceden yükle
  }

  @override
  void dispose() {
    _dreamController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ========== DATA İŞLEMLERİ ==========

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium =
        PurchaseService().isPremium || prefs.getBool('is_premium') == true;

    final savedHistory = prefs.getString('dream_history');
    List<Map<String, dynamic>> history = [];

    if (savedHistory != null && savedHistory.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedHistory);
        if (decoded is List) {
          history = List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e as Map)));
        }
      } catch (e) {
        debugPrint("Geçmiş yükleme hatası: $e");
      }
    }

    // 11 Ücretsiz Hak Kontrolü
    int? savedLimit = prefs.getInt('dream_limit');
    bool hasGotten11 = prefs.getBool('got_11_dreams') ?? false;

    if (!hasGotten11 && !isPremium) {
      savedLimit = 11;
      await prefs.setBool('got_11_dreams', true);
      await prefs.setInt('dream_limit', 11);
    }

    setState(() {
      _isPremium = isPremium;
      _dreamLimit = isPremium ? 9999 : (savedLimit ?? 11);
      _dreamHistory = history;
    });
  }

  Future<void> _saveDream(Map<String, dynamic> dream) async {
    _dreamHistory.insert(0, dream);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dream_history', jsonEncode(_dreamHistory));

    if (!_isPremium) {
      _dreamLimit--;
      await prefs.setInt('dream_limit', _dreamLimit);
    }
  }

  // 🎥 REKLAM İZLEME FONKSİYONU
  Future<void> _watchAdForDream() async {
    await showRewardedAdWithFeedback(
      context: context,
      onRewardEarned: (amount) async {
        setState(() {
          _dreamLimit += amount; // Genelde +1 gelir
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('dream_limit', _dreamLimit);

        if (mounted) {
          _showMessage("Harika! +$amount rüya hakkı kazandın.",
              Icons.check_circle, AppTheme.sageGreen);
        }
      },
    );
  }

  // ========== RÜYA YORUMLAMA ==========

  Future<void> _interpretDream() async {
    // Validasyonlar
    if (_dreamController.text.trim().isEmpty) {
      _showMessage(
          "Lütfen rüyanı anlat.", Icons.warning_amber_rounded, Colors.orange);
      return;
    }

    // Limit Kontrolü
    if (!_isPremium && _dreamLimit <= 0) {
      _showLimitDialog(); // 👈 Yeni Dialog
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _getAIInterpretation();
      final dream = _createDreamObject(result);

      await _saveDream(dream);
      setState(() => _isLoading = false);

      if (mounted) {
        _showResultDialog(result);
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage("Yorumlanırken bir sorun oluştu. Lütfen tekrar dene.",
            Icons.error_outline, Colors.red);
      }
      debugPrint("Hata: $e");
    }
  }

  Future<Map<String, dynamic>> _getAIInterpretation() async {
    final prompt = _buildPrompt();
    final response = await _aiService
        .sendMessage(prompt)
        .timeout(const Duration(seconds: 45));

    if (response == null || response.trim().isEmpty) {
      throw Exception("AI boş yanıt döndü");
    }

    String clean =
        response.trim().replaceAll('```json', '').replaceAll('```', '').trim();

    final result = jsonDecode(clean);

    if (!result.containsKey('interpretation')) {
      throw Exception("Yanıt formatı hatalı");
    }

    return result;
  }

  String _buildPrompt() {
    return """
Kullanıcı şu rüyayı gördü:
"${_dreamController.text.trim()}"

İslami kaynaklara göre (İbn Sirin, İmam Nablusi referanslı) rüyayı en isabetli ve detaylı şekilde analiz et. 
Rüyayı anlatan kişiyi rahatlatacak samimi, manevi ve rehberlik edici bir dil kullan.

Sadece JSON formatında yanıt ver:
{
  "interpretation": "Detaylı yorum metni (en az 4-5 cümle)",
  "islamic_source": "Kaynak (Örn: İbn Sirin)",
  "symbols": ["Sembol 1", "Sembol 2", "Sembol 3"],
  "advice": "Kısa manevi tavsiye",
  "mood": "positive/negative/neutral",
  "related_verse": "İlgili ayet veya hadis meali"
}
""";
  }

  Map<String, dynamic> _createDreamObject(Map<String, dynamic> result) {
    return {
      "date": DateTime.now().toIso8601String(),
      "dream": _dreamController.text.trim(),
      "interpretation": result["interpretation"] ?? "Yorum bulunamadı",
      "source": result["islamic_source"] ?? "Bilinmeyen",
      "symbols": result["symbols"] ?? [],
      "advice": result["advice"] ?? "",
      "mood": result["mood"] ?? "neutral",
      "related_verse": result["related_verse"] ?? "",
      "category": "Rüya Analizi",
    };
  }

  void _resetForm() {
    _dreamController.clear();
  }

  // ========== UI HELPERS ==========

  void _showMessage(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.outfit(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.midnightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.premiumGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.moonStars(PhosphorIconsStyle.fill),
                      color: AppTheme.premiumGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Rüya Tabiri",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result["interpretation"] ?? "Yorum bulunamadı",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Semboller
                    if (result["symbols"] != null &&
                        (result["symbols"] as List).isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (result["symbols"] as List)
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sageGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppTheme.sageGreen
                                            .withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    s.toString(),
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.sageGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildInfoBox(
                      PhosphorIcons.bookOpenText(),
                      "Kaynak: ${result["islamic_source"] ?? "Bilinmiyor"}",
                      AppTheme.premiumGold,
                    ),

                    if (result["advice"]?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        PhosphorIcons.lightbulb(),
                        result["advice"].toString(),
                        Colors.blueAccent,
                        isAdvice: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String text, Color color,
      {bool isAdvice = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💎 LİMİT DİALOG (REKLAM & PREMIUM)
  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                color: AppTheme.premiumGold, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Rüya Hakkın Bitti",
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ücretsiz rüya tabiri limitin olan 11 hakka ulaştın. Sınırsız analiz için Premium'a geçebilirsin:",
              style: GoogleFonts.outfit(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Premium Butonu
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PremiumScreen()),
                ).then((_) => _loadData());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.premiumGold,
                      AppTheme.premiumGold.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.premiumGold.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
                        color: AppTheme.midnightBlue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Premium'a Geç",
                              style: GoogleFonts.outfit(
                                  color: AppTheme.midnightBlue,
                                  fontWeight: FontWeight.bold)),
                          Text("Sınırsız Rüya & Analiz",
                              style: GoogleFonts.outfit(
                                  color: AppTheme.midnightBlue.withOpacity(0.7),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppTheme.midnightBlue.withOpacity(0.5),
                        size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInterpreterTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: !_isPremium
          ? const SafeArea(
              child: SizedBox(
                height: 50,
                child: Center(child: BannerAdWidget()),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.midnightBlue,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Rüya Tabiri",
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        // Tıklanabilir Hak Göstergesi
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (!_isPremium) {
                  _showLimitDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text("premium.unlimited_rights".tr()),
                      backgroundColor: AppTheme.premiumGold,
                      duration: Duration(seconds: 2)));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPremium
                      ? AppTheme.premiumGold.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPremium
                        ? AppTheme.premiumGold.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPremium
                          ? PhosphorIcons.crownSimple(PhosphorIconsStyle.fill)
                          : PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                      size: 14,
                      color: _isPremium
                          ? AppTheme.premiumGold
                          : AppTheme.sageGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPremium ? "Premium" : "$_dreamLimit Hak",
                      style: GoogleFonts.outfit(
                        color: _isPremium ? AppTheme.premiumGold : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!_isPremium) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.add_circle,
                          color: AppTheme.sageGreen, size: 12),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.premiumGold,
        indicatorWeight: 3,
        labelColor: AppTheme.premiumGold,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: "Yeni Tabir"),
          Tab(text: "Geçmiş"),
        ],
      ),
    );
  }

  // ========== YENİ TABİR EKRANI ==========

  Widget _buildInterpreterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 32),
          _buildDreamInput(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.premiumGold.withOpacity(0.15),
            AppTheme.premiumGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.premiumGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              color: AppTheme.premiumGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Rüyanızı detaylı anlatın, İslami kaynaklar ışığında manevi yorumunu alın.",
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDreamInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rüya Detayı",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _dreamController,
            maxLines: 6,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
            cursorColor: AppTheme.premiumGold,
            decoration: InputDecoration(
              hintText: "Rüyanızı buraya yazın...",
              hintStyle: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _interpretDream,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.premiumGold,
          foregroundColor: AppTheme.midnightBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppTheme.premiumGold.withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.midnightBlue,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Yorumla",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== GEÇMİŞ EKRANI ==========

  Widget _buildHistoryTab() {
    if (_dreamHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.scroll(PhosphorIconsStyle.thin),
                  size: 48, color: Colors.white30),
            ),
            const SizedBox(height: 16),
            Text(
              "Henüz kaydedilmiş rüya yok",
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _dreamHistory.length,
      itemBuilder: (context, index) {
        final dream = _dreamHistory[index];
        final date = DateTime.parse(dream["date"]);
        final formattedDate =
            DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(date);

        return GestureDetector(
          onTap: () => _showResultDialog(dream),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.premiumGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dream["category"] ?? "Genel",
                        style: GoogleFonts.outfit(
                          color: AppTheme.premiumGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dream["dream"] ?? "",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIcons.arrowBendDownRight(),
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dream["interpretation"] ?? "",
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
