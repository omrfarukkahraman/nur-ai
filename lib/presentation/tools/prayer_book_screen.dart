import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Clipboard için
import '../../core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart'; // Paylaşım için
import 'package:phosphor_flutter/phosphor_flutter.dart'; // İkonlar için

class PrayerBookScreen extends StatelessWidget {
  const PrayerBookScreen({super.key});

  // --- GENİŞLETİLMİŞ DUA VERİTABANI (20 Adet) ---
  final List<Map<String, String>> prayers = const [
    // --- GÜNLÜK VE HUZUR ---
    {
      "title": "Sıkıntı Anında Okunacak Dua",
      "arabic": "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي",
      "turkish": "Rabbişrah lî sadrî ve yessir lî emrî",
      "meaning": "Rabbim! Göğsümü genişlet, işimi kolaylaştır.",
      "category": "Huzur",
    },
    {
      "title": "Sabah Akşam Korunma Duası",
      "arabic":
          "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
      "turkish":
          "Bismillâhillezi lâ yedurru ma’asmihi şey’ün fil erdı ve lâ fis-semâi ve hüves-semîul alîm.",
      "meaning":
          "İsmiyle yerde ve gökte hiçbir şeyin zarar veremeyeceği Allah'ın adıyla. O, hakkıyla işiten ve bilendir.",
      "category": "Korunma",
    },
    {
      "title": "Zor İşlerin Kolaylaşması İçin",
      "arabic":
          "اللَّهُمَّ لاَ سَهْلَ إِلاَّ مَا جَعَلْتَهُ سَهْلاً، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلاً",
      "turkish":
          "Allâhümme lâ sehle illâ mâ ce’altehû sehlen, ve ente tec’alü’l-hazne izâ şi’te sehlen.",
      "meaning":
          "Allah'ım! Senin kolaylaştırdığından başka kolay yoktur. Sen istersen zoru kolay kılarsın.",
      "category": "Huzur",
    },

    // --- RIZIK VE BORÇ ---
    {
      "title": "Rızık ve Bereket Duası",
      "arabic":
          "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ",
      "turkish":
          "Allahummekfinî bi-halâlike an harâmike ve ağninî bi-fazlike ammen sivâke",
      "meaning":
          "Allah'ım! Helâl olan nimetlerinle yetinmemi sağla, haramdan beni koru. Lütfunla beni Senden başkasına muhtaç etme.",
      "category": "Rızık",
    },
    {
      "title": "Borçtan Kurtulma Duası",
      "arabic":
          "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ",
      "turkish":
          "Allâhümme innî eûzü bike mine’l-hemmi ve’l-hazeni ve’l-aczi ve’l-keseli ve’l-buhli ve’l-cübni ve dalei’d-deyni ve galebeti’r-ricâl.",
      "meaning":
          "Allah'ım! Üzüntü ve kederden, acizlik ve tembellikten, cimrilik ve korkaklıktan, borç yükünden ve insanların kahrından sana sığınırım.",
      "category": "Borç",
    },

    // --- SAĞLIK VE ŞİFA ---
    {
      "title": "Şifa Duası",
      "arabic":
          "أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَك",
      "turkish": "Es'elü'llâhe'l-azîm Rabbe'l-arşi'l-azîm en yeşfiyeke",
      "meaning":
          "Büyük Arş'ın Rabbi olan Yüce Allah'tan sana şifa vermesini dilerim.",
      "category": "Şifa",
    },
    {
      "title": "Nazar Duası",
      "arabic": "مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ",
      "turkish": "MâşâAllahü lâ kuvvete illâ billâh",
      "meaning": "Allah'ın dilediği olur. Kuvvet ancak Allah'tandır.",
      "category": "Korunma",
    },

    // --- AİLE VE EVLİLİK ---
    {
      "title": "Hayırlı Eş ve Çocuk İsteği",
      "arabic":
          "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
      "turkish":
          "Rabbena heb lenâ min ezvâcinâ ve zurriyyâtinâ kurrate a’yunin vec’alnâ lil muttekîne imâmâ.",
      "meaning":
          "Rabbimiz! Bize eşlerimizden ve soyumuzdan göz aydınlığı olacak kimseler ihsan et ve bizi takva sahiplerine önder kıl.",
      "category": "Aile",
    },
    {
      "title": "Anne Baba İçin Dua",
      "arabic": "رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا",
      "turkish": "Rabbirhamhumâ kemâ rabbeyânî sagîrâ.",
      "meaning":
          "Rabbim! Onlar beni küçükken nasıl şefkatle büyüttülerse, sen de onlara merhamet et.",
      "category": "Aile",
    },

    // --- BAŞARI VE İLİM ---
    {
      "title": "Sınav ve Başarı Duası",
      "arabic": "رَبِّ زِدْنِي عِلْمًا وَفَهْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ",
      "turkish": "Rabbi zidnî ilmen ve fehmen ve elhıknî bissâlihîn.",
      "meaning":
          "Rabbim! İlmimi ve anlayışımı artır ve beni salih kulların arasına kat.",
      "category": "Başarı",
    },
    {
      "title": "Konuşma Kolaylığı Duası",
      "arabic": "وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي يَفْقَهُوا قَوْلِي",
      "turkish": "Vahlul ukdeten min lisânî yefkahû kavlî.",
      "meaning": "Dilimdeki düğümü çöz ki sözümü iyi anlasınlar.",
      "category": "Başarı",
    },

    // --- TÖVBE VE BAĞIŞLANMA ---
    {
      "title": "Seyyidül İstiğfar (Büyük Tövbe)",
      "arabic":
          "اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ...",
      "turkish":
          "Allahümme ente Rabbî lâ ilâhe illâ ente halaktenî ve ene abdüke...",
      "meaning":
          "Allah'ım! Sen benim Rabbimsin. Senden başka ilah yoktur. Beni Sen yarattın ve ben Senin kulunum...",
      "category": "Tövbe",
    },
    {
      "title": "Kısa Tövbe Duası",
      "arabic":
          "رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      "turkish":
          "Rabbenâ zalemnâ enfusenâ ve in lem tagfir lenâ ve terhamnâ lenekûnenne minel hâsirîn",
      "meaning":
          "Rabbimiz! Biz kendimize zulmettik. Eğer bizi bağışlamaz ve bize acımazsan, muhakkak ziyana uğrayanlardan oluruz.",
      "category": "Tövbe",
    },

    // --- DİĞER DURUMLAR ---
    {
      "title": "Yolculuk Duası",
      "arabic":
          "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ",
      "turkish":
          "Subhânellezî sehhara lenâ hâzâ ve mâ künnâ lehû mukrinîn ve innâ ilâ Rabbinâ le-munkalibûn.",
      "meaning":
          "Bunu bizim hizmetimize veren Allah'ı tesbih ederiz; yoksa biz buna güç yetiremezdik. Muhakkak biz Rabbimize döneceğiz.",
      "category": "Yolculuk",
    },
    {
      "title": "Yemek Duası (Kısa)",
      "arabic":
          "اَلْحَمْدُ لِلّٰهِ الَّذِى اَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مِنَ الْمُسْلِمِينَ",
      "turkish":
          "Elhamdülillâhillezî et’amenâ ve sekânâ ve cealenâ minel müslimîn.",
      "meaning": "Bizi yediren, içiren ve Müslüman kılan Allah'a hamdolsun.",
      "category": "Şükür",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Dua Hazinesi",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: prayers.length,
        itemBuilder: (context, index) {
          final prayer = prayers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                collapsedIconColor: AppTheme.premiumGold,
                iconColor: AppTheme.premiumGold,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

                // Başlık Kısmı
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.premiumGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.handsPraying(),
                    size: 20,
                    color: AppTheme.premiumGold,
                  ),
                ),
                title: Text(
                  prayer["title"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  prayer["category"]!,
                  style: GoogleFonts.outfit(
                    color: AppTheme.sageGreen,
                    fontSize: 12,
                  ),
                ),

                // Açılınca Görünecek Detaylar
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.premiumGold.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Arapça
                        Text(
                          prayer["arabic"]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            color: AppTheme.premiumGold,
                            fontSize: 24,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Okunuş
                        Text(
                          prayer["turkish"]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),
                        // Anlam
                        Text(
                          prayer["meaning"]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ALT AKSİYONLAR (Kopyala ve Paylaş)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // KOPYALA BUTONU
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  "${prayer["title"]}\n${prayer["arabic"]}\n${prayer["meaning"]}",
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("common.copied_prayer".tr())),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy,
                              size: 18,
                              color: Colors.white30,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Kopyala",
                              style: GoogleFonts.outfit(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // PAYLAŞ BUTONU (AKTİF)
                      InkWell(
                        onTap: () {
                          final String shareText =
                              """
${prayer["title"]}

${prayer["arabic"]}

Okunuşu: ${prayer["turkish"]}

Anlamı: "${prayer["meaning"]}"

Nûr AI ile huzur bul.
""";
                          Share.share(shareText);
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.share,
                              size: 18,
                              color: AppTheme.premiumGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Paylaş",
                              style: GoogleFonts.outfit(
                                color: AppTheme.premiumGold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
