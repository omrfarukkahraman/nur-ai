import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/rewarded_ad_manager.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/purchase_service.dart';
import '../../presentation/premium/premium_screen.dart';
import '../../presentation/widgets/banner_ad_widget.dart';


class ChatScreen extends StatefulWidget {
  final String mood;
  const ChatScreen({super.key, required this.mood});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;
  bool _isPremium = false;
  int _messageLimit = 5; // Default

  final RewardedAdManager _adManager = RewardedAdManager();

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Reklam servisini başlat (Hata önleyici)
    try {
      _adManager.loadAd();
    } catch (_) {}

    if (widget.mood == "Genel") {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _messages.add({
              "isUser": false,
              "message":
                  "Selamün Aleyküm! 👋\n\nBugün kalbinin sesini dinlemeye geldim. Senin için ne yapabilirim?",
              "attachments": [],
              "suggestions": [
                "Bana bir ayet oku",
                "Huzursuz hissediyorum",
                "Rızık duası nedir?",
              ],
            });
          });
        }
      });
    } else {
      _sendMessage(
        "Selamün Aleyküm, şu an kendimi ${widget.mood} hissediyorum.",
        isAutomatic: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // RevenueCat'ten güncel premium durumunu kontrol et
      try {
        await PurchaseService().checkSubscriptionStatus();
        _isPremium = PurchaseService().isPremium;
      } catch (_) {
        _isPremium = false;
      }

      setState(() {
        // Premium: 50 mesaj, Free: 5 mesaj
        final lastReset = prefs.getString('last_limit_reset') ?? '';
        final today = DateTime.now().toIso8601String().split('T')[0];

        if (lastReset != today) {
          // Yeni gün, limiti sıfırla
          _messageLimit = _isPremium ? 50 : 5;
          prefs.setString('last_limit_reset', today);
          prefs.setInt('message_limit', _messageLimit);
        } else {
          _messageLimit =
              prefs.getInt('message_limit') ?? (_isPremium ? 50 : 5);
        }
      });
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    }
  }

  Future<void> _saveMessageLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('message_limit', _messageLimit);
  }

  Future<void> _sendMessage(String text, {bool isAutomatic = false}) async {
    if (text.trim().isEmpty) return;

    // Premium kontrolü
    if (!isAutomatic && !_isPremium && _messageLimit <= 0) {
      _showPremiumDialog();
      return;
    }

    setState(() {
      _messages.add({"isUser": true, "message": text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final responseText = await AIService().sendMessage(text).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException("Zaman aşımı"),
          );

      if (responseText == null || responseText.isEmpty) {
        throw Exception("AI boş yanıt verdi");
      }

      String cleanText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      // JSON formatı kontrolü
      if (!cleanText.startsWith('{')) {
        cleanText = '{"message": "$cleanText", "suggestions": []}';
      }

      final jsonResponse = jsonDecode(cleanText);

      List<dynamic> rawAttachments = jsonResponse["attachments"] ?? [];
      List<Map<String, dynamic>> processedAttachments = [];

      for (var item in rawAttachments) {
        if (item is Map<String, dynamic>) {
          item['globalKey'] = GlobalKey();
          processedAttachments.add(item);
        }
      }

      setState(() {
        _messages.add({
          "isUser": false,
          "message": jsonResponse["message"] ?? "Yanıt okunamadı.",
          "attachments": processedAttachments,
          "suggestions": jsonResponse["suggestions"] ?? [],
        });
        _isLoading = false;
      });

      // Premium değilse mesaj limitini düşür
      if (!isAutomatic && !_isPremium) {
        setState(() => _messageLimit--);
        await _saveMessageLimit();

        if (_messageLimit == 3) {
          _addSystemMessage(
            "📢 Sadece 3 mesaj hakkın kaldı!\n\nPremium'a geç, sınırsız sohbet et. 💎",
            ["Premium'a Geç 💎", "Devam Et ✍️"],
          );
        } else if (_messageLimit == 1) {
          _addSystemMessage(
            "⚠️ Son mesaj hakkın!\n\nİstersen reklam izleyerek +5 mesaj hakkı kazanabilirsin 🎥",
            ["Reklam İzle 🎥", "Premium'a Geç 💎"],
          );
        }
      }
    } on TimeoutException {
      _showErrorMessage("Yanıt çok uzun sürdü ⏱️\n\nBir daha dener misin?");
    } on FormatException {
      _showErrorMessage("AI yanıtı anlaşılmadı 🤔\n\nTekrar dener misin?");
    } catch (e) {
      _showErrorMessage(
        "Bir bağlantı sorunu oluştu 😕\n\nLütfen internetini kontrol et ve tekrar dene.",
      );
      debugPrint("Hata Detayı: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scrollToBottom();
    }
  }

  void _addSystemMessage(String message, List<String> suggestions) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add({
            "isUser": false,
            "message": message,
            "attachments": [],
            "suggestions": suggestions,
            "isSystemMessage": true,
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      _messages.add({
        "isUser": false,
        "message": message,
        "attachments": [],
        "suggestions": ["Tekrar Dene 🔄", "Ana Ekrana Dön 🏠"],
        "isSystemMessage": true,
      });
      _isLoading = false;
    });
  }

  // 📸 PAYLAŞIM FONKSİYONU
  Future<void> _shareCardAsImage(
      GlobalKey key, String title, BuildContext buttonContext) async {
    try {
      if (key.currentContext == null) {
        debugPrint("❌ Paylaşım: key.currentContext null");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Görüntü oluşturulamadı, lütfen tekrar deneyin.')),
          );
        }
        return;
      }

      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint("❌ Paylaşım: boundary null");
        return;
      }

      // Render tamamlanmasını bekle (debugNeedsPaint RELEASE modda çöker!)
      await Future.delayed(const Duration(milliseconds: 100));

      ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint("❌ Paylaşım: byteData null");
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/nur_ai_card_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      final box = buttonContext.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Nûr AI ile Paylaşıldı 🌟',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('❌ Paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım yapılamadı.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _watchAdForMessages() async {
    await showRewardedAdWithFeedback(
      context: context,
      onRewardEarned: (earnedMessages) async {
        setState(() {
          _messageLimit += earnedMessages;
        });
        await _saveMessageLimit();

        _addSystemMessage(
          "Harika! 🎉\n\n$earnedMessages mesaj hakkı kazandın. Şimdi konuşmaya devam edebiliriz!",
          ["Devam Edelim 💬"],
        );
      },
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.crownSimple(PhosphorIconsStyle.fill),
              color: AppTheme.premiumGold,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Mesaj Limitin Doldu",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bugünlük ücretsiz mesaj hakkın bitti.",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.premiumGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Premium'da Neler Var?",
                    style: GoogleFonts.outfit(
                      color: AppTheme.premiumGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _premiumFeature("Sınırsız AI Sohbet"),
                  _premiumFeature("Sınırsız AI Sohbet"),
                  _premiumFeature("Reklamsız Deneyim"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "veya",
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Reklam izleyerek +3 mesaj kazanabilirsin 🎥",
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _watchAdForMessages();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, color: AppTheme.sageGreen),
                const SizedBox(width: 8),
                Text(
                  "Reklam İzle 🎥",
                  style: GoogleFonts.outfit(
                    color: AppTheme.sageGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.premiumGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Premium ekranına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PremiumScreen()),
              ).then((_) {
                // Premium alındıktan sonra veriyi yenile
                _loadUserData();
              });
            },
            child: Text(
              "Premium'a Geç 💎",
              style: GoogleFonts.outfit(
                color: AppTheme.midnightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            color: AppTheme.sageGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.midnightBlue,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.chatTeardropText(PhosphorIconsStyle.fill),
                color: AppTheme.premiumGold,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Nûr AI",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        actions: [
          if (!_isPremium)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _messageLimit <= 3
                    ? Colors.red.withOpacity(0.2)
                    : AppTheme.sageGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _messageLimit <= 3 ? Colors.red : AppTheme.sageGreen,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.chatCircleText(PhosphorIconsStyle.fill),
                    color: _messageLimit <= 3 ? Colors.red : AppTheme.sageGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$_messageLimit",
                    style: GoogleFonts.outfit(
                      color:
                          _messageLimit <= 3 ? Colors.red : AppTheme.sageGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ÜST BANNER REKLAM (Premium değilse)
          if (!_isPremium) const BannerAdWidget(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(_messages[index], index),
            ),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 30, bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 6),
            _buildDot(1),
            const SizedBox(width: 6),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.premiumGold,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg, int messageIndex) {
    bool isUser = msg['isUser'] ?? false;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 50),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.sageGreen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Text(
            msg['message'] ?? "",
            style: GoogleFonts.outfit(
              color: AppTheme.midnightBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else {
      final attachments = msg['attachments'] as List<dynamic>? ?? [];
      final suggestions = msg['suggestions'] as List<dynamic>? ?? [];

      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => _copyMessage(msg['message'] ?? ""),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, right: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  msg['message'] ?? "...",
                  style: GoogleFonts.outfit(color: Colors.white, height: 1.5),
                ),
              ),
            ),
            ...List.generate(attachments.length, (attachmentIndex) {
              final item =
                  attachments[attachmentIndex] as Map<String, dynamic>? ?? {};
              final type = item['type'] as String?;
              final data = item['data'] as Map<String, dynamic>? ?? {};

              GlobalKey cardKey;
              if (item['globalKey'] != null && item['globalKey'] is GlobalKey) {
                cardKey = item['globalKey'];
              } else {
                cardKey = GlobalKey();
                item['globalKey'] = cardKey;
              }

              if (type == 'verse') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildVerseCard(data, cardKey),
                );
              } else if (type == 'hadith') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildHadithCard(data, cardKey),
                );
              } else if (type == 'zikr') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildZikrCard(data, cardKey),
                );
              } else if (type == 'dua') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildDuaCard(data, cardKey),
                );
              } else if (type == 'fetva') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildFetvaCard(data, cardKey),
                );
              }
              return const SizedBox.shrink();
            }),
            if (suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions
                      .map((s) => _buildSuggestionChip(s.toString()))
                      .toList(),
                ),
              ),
          ],
        ),
      );
    }
  }

  // 📸 AYET KARTI
  Widget _buildVerseCard(Map<String, dynamic> data, GlobalKey key) {
    return Stack(
      children: [
        // Resim olarak yakalanacak kısım (Butonsuz)
        RepaintBoundary(
          key: key,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  AppTheme.midnightBlue, // Arka plan rengi (şeffaflığı önler)
              gradient: LinearGradient(
                colors: [
                  AppTheme.sageGreen.withOpacity(0.15),
                  AppTheme.sageGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.sageGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.bookOpenText(PhosphorIconsStyle.fill),
                        color: AppTheme.sageGreen.withOpacity(0.8), size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['arabic'] ?? "",
                  style: GoogleFonts.amiriQuran(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "\"${data['meal'] ?? ''}\"",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Divider(color: AppTheme.sageGreen.withOpacity(0.2)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['source'] ?? "",
                        style: GoogleFonts.outfit(
                          color: AppTheme.sageGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Marka İmzası
                    Row(
                      children: [
                        Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            size: 14,
                            color: AppTheme.sageGreen.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          "Nûr AI",
                          style: GoogleFonts.outfit(
                            color: AppTheme.sageGreen.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Paylaş Butonu (Kartın üzerine floating olarak eklenir, resme girmez)
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (buttonContext) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.midnightBlue.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                  color: AppTheme.sageGreen,
                  size: 20,
                ),
                tooltip: "Paylaş",
                onPressed: () => _shareCardAsImage(key, "Ayet", buttonContext),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 📸 HADİS KARTI
  Widget _buildHadithCard(Map<String, dynamic> data, GlobalKey key) {
    return Stack(
      children: [
        RepaintBoundary(
          key: key,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.midnightBlue,
              gradient: LinearGradient(
                colors: [
                  AppTheme.premiumGold.withOpacity(0.15),
                  AppTheme.premiumGold.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.premiumGold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.scroll(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold.withOpacity(0.8), size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['arabic'] ?? "",
                  style: GoogleFonts.amiriQuran(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "\"${data['meal'] ?? ''}\"",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Divider(color: AppTheme.premiumGold.withOpacity(0.2)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['source'] ?? "Hadis-i Şerif",
                        style: GoogleFonts.outfit(
                          color: AppTheme.premiumGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            size: 14,
                            color: AppTheme.premiumGold.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          "Nûr AI",
                          style: GoogleFonts.outfit(
                            color: AppTheme.premiumGold.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (buttonContext) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.midnightBlue.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                  color: AppTheme.premiumGold,
                  size: 20,
                ),
                tooltip: "Paylaş",
                onPressed: () => _shareCardAsImage(key, "Hadis", buttonContext),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 📸 ZİKİR KARTI
  Widget _buildZikrCard(Map<String, dynamic> data, GlobalKey key) {
    return Stack(
      children: [
        RepaintBoundary(
          key: key,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.premiumGold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.premiumGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.handsPraying(PhosphorIconsStyle.fill),
                        color: AppTheme.premiumGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? "Zikir",
                            style: GoogleFonts.amiriQuran(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['turkish'] ?? data['meaning'] ?? "",
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.premiumGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${data['count'] ?? 33} Kere",
                        style: GoogleFonts.outfit(
                          color: AppTheme.premiumGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        size: 14, color: Colors.white30),
                    const SizedBox(width: 6),
                    Text(
                      "Nûr AI",
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (buttonContext) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                  color: AppTheme.premiumGold,
                  size: 20,
                ),
                tooltip: "Paylaş",
                onPressed: () => _shareCardAsImage(key, "Zikir", buttonContext),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 🤲 DUA KARTI
  Widget _buildDuaCard(Map<String, dynamic> data, GlobalKey key) {
    return Stack(
      children: [
        RepaintBoundary(
          key: key,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.midnightBlue,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D9488).withOpacity(0.15),
                  const Color(0xFF0D9488).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.handsPraying(PhosphorIconsStyle.fill),
                        color: const Color(0xFF5EEAD4), size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['arabic'] != null && data['arabic'].toString().isNotEmpty)
                  Text(
                    data['arabic'],
                    style: GoogleFonts.amiriQuran(
                      fontSize: 26,
                      color: Colors.white,
                      height: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['meal'] ?? "",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (data['source'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    data['source'],
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF5EEAD4).withOpacity(0.7),
                        fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (btnCtx) {
            return IconButton(
              icon: Icon(
                PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                color: const Color(0xFF5EEAD4).withOpacity(0.7),
                size: 20,
              ),
              onPressed: () => _shareCardAsImage(key, "Dua", btnCtx),
            );
          }),
        ),
      ],
    );
  }

  // ⚖️ FETVA KARTI
  Widget _buildFetvaCard(Map<String, dynamic> data, GlobalKey key) {
    // Hüküm rengini belirle
    Color rulingColor;
    final ruling = (data['ruling'] ?? "").toString().toLowerCase();
    if (ruling.contains('haram')) {
      rulingColor = Colors.red;
    } else if (ruling.contains('mekruh')) {
      rulingColor = Colors.orange;
    } else if (ruling.contains('helal') || ruling.contains('mübah')) {
      rulingColor = Colors.green;
    } else if (ruling.contains('farz') || ruling.contains('vacip')) {
      rulingColor = const Color(0xFF3B82F6);
    } else if (ruling.contains('müstehap') || ruling.contains('sünnet')) {
      rulingColor = const Color(0xFF8B5CF6);
    } else {
      rulingColor = AppTheme.premiumGold;
    }

    return Stack(
      children: [
        RepaintBoundary(
          key: key,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.midnightBlue,
              gradient: LinearGradient(
                colors: [
                  rulingColor.withOpacity(0.12),
                  rulingColor.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rulingColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.scales(PhosphorIconsStyle.fill),
                        color: rulingColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "FETVA",
                      style: GoogleFonts.outfit(
                        color: rulingColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (data['ruling'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: rulingColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: rulingColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          data['ruling'],
                          style: GoogleFonts.outfit(
                            color: rulingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['detail'] != null)
                  Text(
                    data['detail'],
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                if (data['source'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(PhosphorIcons.bookOpenText(),
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          data['source'],
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  "Allahu a'lem (En doğrusunu Allah bilir)",
                  style: GoogleFonts.amiri(
                    color: rulingColor.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Builder(builder: (btnCtx) {
            return IconButton(
              icon: Icon(
                PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                color: rulingColor.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () => _shareCardAsImage(key, "Fetva", btnCtx),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    bool isPremium =
        suggestion.contains("Premium") || suggestion.contains("💎");
    return GestureDetector(
      onTap: () {
        if (isPremium) {
          _showPremiumDialog();
        } else if (suggestion.contains("Reklam") || suggestion.contains("🎥")) {
          _watchAdForMessages();
        } else if (suggestion.contains("Ana Ekrana") ||
            suggestion.contains("🏠")) {
          Navigator.pop(context);
        } else {
          _sendMessage(suggestion);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPremium
              ? AppTheme.premiumGold.withOpacity(0.15)
              : AppTheme.midnightBlue,
          border: Border.all(
            color: isPremium
                ? AppTheme.premiumGold.withOpacity(0.5)
                : AppTheme.premiumGold.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          suggestion,
          style: GoogleFonts.outfit(
            color: isPremium
                ? AppTheme.premiumGold
                : AppTheme.premiumGold.withOpacity(0.9),
            fontSize: 13,
            fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              PhosphorIcons.check(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text("Mesaj kopyalandı", style: GoogleFonts.outfit()),
          ],
        ),
        backgroundColor: AppTheme.sageGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.midnightBlue,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "İçini dök...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                suffixIcon: !_isPremium && _messageLimit <= 3
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          PhosphorIcons.warning(PhosphorIconsStyle.fill),
                          color: Colors.red,
                          size: 20,
                        ),
                      )
                    : null,
              ),
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.premiumGold,
                    AppTheme.premiumGold.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.premiumGold.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill),
                color: AppTheme.midnightBlue,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
