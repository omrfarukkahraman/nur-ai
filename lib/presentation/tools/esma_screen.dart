import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';

class EsmaScreen extends StatelessWidget {
  const EsmaScreen({super.key});

  final List<Map<String, String>> esmalar = const [
    {
      "arabic": "الرَّحْمَنُ",
      "name": "Er-Rahmân",
      "meaning": "Dünyada ayırt etmeksizin tüm canlılara merhamet eden.",
    },
    {
      "arabic": "الرَّحِيمُ",
      "name": "Er-Rahîm",
      "meaning": "Ahirette sadece müminlere merhamet eden.",
    },
    {
      "arabic": "الْمَلِكُ",
      "name": "El-Melik",
      "meaning": "Mülkün gerçek sahibi, her şeye gücü yeten.",
    },
    {
      "arabic": "الْقُدُّوسُ",
      "name": "El-Kuddûs",
      "meaning": "Her türlü eksiklikten münezzeh, tertemiz olan.",
    },
    {
      "arabic": "السَّلاَمُ",
      "name": "Es-Selâm",
      "meaning": "Kullarına selamet ve esenlik veren.",
    },
    {
      "arabic": "الْمُؤْمِنُ",
      "name": "El-Mü'min",
      "meaning": "Gönüllerde iman ışığı uyandıran, güven veren.",
    },
    {
      "arabic": "الْمُهَيْمِنُ",
      "name": "El-Müheymin",
      "meaning": "Gözetip koruyan, her şeyi kontrolü altında tutan.",
    },
    {
      "arabic": "الْعَزِيزُ",
      "name": "El-Azîz",
      "meaning": "İzzet sahibi, her şeye galip gelen.",
    },
    {
      "arabic": "الْجَبَّارُ",
      "name": "El-Cebbâr",
      "meaning": "Dilediğini zorla yaptıran, hükmüne karşı gelinemeyen.",
    },
    {
      "arabic": "الْمُتَكَبِّرُ",
      "name": "El-Mütekebbir",
      "meaning": "Büyüklükte eşi olmayan, azamet sahibi.",
    },
    {
      "arabic": "الْخَالِقُ",
      "name": "El-Hâlık",
      "meaning": "Her şeyi yoktan var eden, yaratan.",
    },
    {
      "arabic": "الْبَارِئُ",
      "name": "El-Bâri",
      "meaning": "Her şeyi kusursuz ve uyumlu yaratan.",
    },
    {
      "arabic": "الْمُصَوِّرُ",
      "name": "El-Musavvir",
      "meaning": "Varlıklara şekil ve suret veren.",
    },
    {
      "arabic": "الْغَفَّارُ",
      "name": "El-Gaffâr",
      "meaning": "Günahları çokça bağışlayan, örten.",
    },
    {
      "arabic": "الْقَهَّارُ",
      "name": "El-Kahhâr",
      "meaning": "Her şeye galip gelen, mutlak hakim.",
    },
    {
      "arabic": "الْوَهَّابُ",
      "name": "El-Vehhâb",
      "meaning": "Karşılıksız bolca veren, ihsan eden.",
    },
    {
      "arabic": "الرَّزَّاقُ",
      "name": "Er-Rezzâk",
      "meaning": "Bütün canlıların rızkını veren.",
    },
    {
      "arabic": "الْفَتَّاحُ",
      "name": "El-Fettâh",
      "meaning": "Her türlü hayır kapılarını açan.",
    },
    {
      "arabic": "الْعَلِيمُ",
      "name": "El-Alîm",
      "meaning": "Her şeyi hakkıyla bilen.",
    },
    {
      "arabic": "الْقَابِضُ",
      "name": "El-Kâbıd",
      "meaning": "Dilediğinin rızkını daraltan, ruhları alan.",
    },
    {
      "arabic": "الْبَاسِطُ",
      "name": "El-Bâsıt",
      "meaning": "Dilediğinin rızkını genişleten, ruhları veren.",
    },
    {
      "arabic": "الْخَافِضُ",
      "name": "El-Hâfıd",
      "meaning": "Kafirleri ve zalimleri alçaltan.",
    },
    {
      "arabic": "الرَّافِعُ",
      "name": "Er-Râfi",
      "meaning": "Müminleri ve itaatkarları yükselten.",
    },
    {
      "arabic": "الْمُعِزُّ",
      "name": "El-Muizz",
      "meaning": "İzzet ve şeref veren, aziz kılan.",
    },
    {
      "arabic": "الْمُذِلُّ",
      "name": "El-Müzil",
      "meaning": "Zillet veren, hor ve hakir kılan.",
    },
    {
      "arabic": "السَّمِيعُ",
      "name": "Es-Semî",
      "meaning": "Her şeyi en iyi işiten.",
    },
    {
      "arabic": "الْبَصِيرُ",
      "name": "El-Basîr",
      "meaning": "Her şeyi en iyi gören.",
    },
    {
      "arabic": "الْحَكَمُ",
      "name": "El-Hakem",
      "meaning": "Mutlak hakim, hakkı batıldan ayıran.",
    },
    {
      "arabic": "الْعَدْلُ",
      "name": "El-Adl",
      "meaning": "Mutlak adalet sahibi, asla zulmetmeyen.",
    },
    {
      "arabic": "اللَّطِيفُ",
      "name": "El-Latîf",
      "meaning": "En ince işlerin bütün inceliklerini bilen, lütuf sahibi.",
    },
    {
      "arabic": "الْخَبِيرُ",
      "name": "El-Habîr",
      "meaning": "Her şeyden haberdar olan.",
    },
    {
      "arabic": "الْحَلِيمُ",
      "name": "El-Halîm",
      "meaning": "Cezada acele etmeyen, yumuşak davranan.",
    },
    {
      "arabic": "الْعَظِيمُ",
      "name": "El-Azîm",
      "meaning": "Büyüklükte benzeri olmayan, pek yüce.",
    },
    {
      "arabic": "الْغَفُورُ",
      "name": "El-Gafûr",
      "meaning": "Affı ve bağışlaması bol olan.",
    },
    {
      "arabic": "الشَّكُورُ",
      "name": "Eş-Şekûr",
      "meaning": "Az amele çok sevap veren.",
    },
    {
      "arabic": "الْعَلِيُّ",
      "name": "El-Aliyy",
      "meaning": "Yüceler yücesi, çok yüce.",
    },
    {
      "arabic": "الْكَبِيرُ",
      "name": "El-Kebîr",
      "meaning": "Büyüklüğüne sınır olmayan.",
    },
    {
      "arabic": "الْحَفِيظُ",
      "name": "El-Hafîz",
      "meaning": "Her şeyi koruyan ve dengede tutan.",
    },
    {
      "arabic": "الْمُقِيتُ",
      "name": "El-Mukît",
      "meaning": "Her yaratılmışın rızkını ve gıdasını veren.",
    },
    {
      "arabic": "الْحَسِيبُ",
      "name": "El-Hasîb",
      "meaning": "Herkesin hesabını en iyi gören.",
    },
    {
      "arabic": "الْجَلِيلُ",
      "name": "El-Celîl",
      "meaning": "Azamet ve celal sahibi.",
    },
    {
      "arabic": "الْكَرِيمُ",
      "name": "El-Kerîm",
      "meaning": "Çok cömert, ikramı bol olan.",
    },
    {
      "arabic": "الرَّقِيبُ",
      "name": "Er-Rakîb",
      "meaning": "Her şeyi gözetleyen, kontrolü altında tutan.",
    },
    {
      "arabic": "الْمُجِيبُ",
      "name": "El-Mucîb",
      "meaning": "Duaları kabul eden.",
    },
    {
      "arabic": "الْوَاسِعُ",
      "name": "El-Vâsi",
      "meaning": "İlmi ve rahmeti her şeyi kuşatan.",
    },
    {
      "arabic": "الْحَكِيمُ",
      "name": "El-Hakîm",
      "meaning": "Her işi hikmetli olan.",
    },
    {
      "arabic": "الْوَدُودُ",
      "name": "El-Vedûd",
      "meaning": "Kullarını seven ve sevilmeye layık olan.",
    },
    {
      "arabic": "الْمَجِيدُ",
      "name": "El-Mecîd",
      "meaning": "Şanı büyük ve yüksek olan.",
    },
    {
      "arabic": "الْبَاعِثُ",
      "name": "El-Bâis",
      "meaning": "Ölüleri dirilten, peygamberler gönderen.",
    },
    {
      "arabic": "الشَّهِيدُ",
      "name": "Eş-Şehîd",
      "meaning": "Her zaman ve her yerde hazır ve nazır olan.",
    },
    {
      "arabic": "الْحَقُّ",
      "name": "El-Hakk",
      "meaning": "Varlığı hiç değişmeden duran, gerçek olan.",
    },
    {
      "arabic": "الْوَكِيلُ",
      "name": "El-Vekîl",
      "meaning": "Kullarının işlerini en iyi yoluna koyan.",
    },
    {
      "arabic": "الْقَوِيُّ",
      "name": "El-Kaviyy",
      "meaning": "Pek güçlü, kuvvetli.",
    },
    {
      "arabic": "الْمَتِينُ",
      "name": "El-Metîn",
      "meaning": "Çok sağlam, sarsılmaz.",
    },
    {
      "arabic": "الْوَلِيُّ",
      "name": "El-Veliyy",
      "meaning": "Müminlerin dostu ve yardımcısı.",
    },
    {
      "arabic": "الْحَمِيدُ",
      "name": "El-Hamîd",
      "meaning": "Her türlü övgüye layık olan.",
    },
    {
      "arabic": "الْمُحْصِي",
      "name": "El-Muhsî",
      "meaning": "Her şeyin sayısını bilen.",
    },
    {
      "arabic": "الْمُبْدِئُ",
      "name": "El-Mübdi",
      "meaning": "Mahlukatı maddesiz ve örneksiz yaratan.",
    },
    {
      "arabic": "الْمُعِيدُ",
      "name": "El-Muîd",
      "meaning": "Yaratılmışları yok ettikten sonra tekrar yaratan.",
    },
    {
      "arabic": "الْمُحْيِي",
      "name": "El-Muhyî",
      "meaning": "Can veren, hayat bahşeden.",
    },
    {
      "arabic": "الْمُمِيتُ",
      "name": "El-Mümît",
      "meaning": "Canlıları öldüren, ölümü yaratan.",
    },
    {
      "arabic": "الْحَيُّ",
      "name": "El-Hayy",
      "meaning": "Ezeli ve ebedi hayat sahibi.",
    },
    {
      "arabic": "الْقَيُّومُ",
      "name": "El-Kayyûm",
      "meaning": "Gökleri, yeri ve her şeyi ayakta tutan.",
    },
    {
      "arabic": "الْوَاجِدُ",
      "name": "El-Vâcid",
      "meaning": "İstediğini istediği zaman bulan.",
    },
    {
      "arabic": "الْمَاجِدُ",
      "name": "El-Mâcid",
      "meaning": "Şanı yüce ve keremi bol olan.",
    },
    {
      "arabic": "الْوَاحِدُ",
      "name": "El-Vâhid",
      "meaning": "Tek olan, eşi ve benzeri olmayan.",
    },
    {
      "arabic": "الصَّمَدُ",
      "name": "Es-Samed",
      "meaning":
          "Her şey kendisine muhtaç olan, kendisi hiçbir şeye muhtaç olmayan.",
    },
    {
      "arabic": "الْقَادِرُ",
      "name": "El-Kâdir",
      "meaning": "Her şeye gücü yeten.",
    },
    {
      "arabic": "الْمُقْتَدِرُ",
      "name": "El-Muktedir",
      "meaning": "Her şeye gücü yeten, kuvvet sahibi.",
    },
    {
      "arabic": "الْمُقَدِّمُ",
      "name": "El-Mukaddim",
      "meaning": "Dilediğini öne alan.",
    },
    {
      "arabic": "الْمُؤَخِّرُ",
      "name": "El-Muahhir",
      "meaning": "Dilediğini arkaya bırakan.",
    },
    {
      "arabic": "الْأَوَّلُ",
      "name": "El-Evvel",
      "meaning": "Her şeyden önce var olan.",
    },
    {
      "arabic": "الْآخِرُ",
      "name": "El-Âhir",
      "meaning": "Her şey yok olduktan sonra baki kalan.",
    },
    {
      "arabic": "الظَّاهِرُ",
      "name": "Ez-Zâhir",
      "meaning": "Varlığı sayısız delillerle açık olan.",
    },
    {
      "arabic": "الْبَاطِنُ",
      "name": "El-Bâtın",
      "meaning": "Akılların idrak edemeyeceği yüceliği gizli olan.",
    },
    {
      "arabic": "الْوَالِي",
      "name": "El-Vâli",
      "meaning": "Kainatı idare eden.",
    },
    {
      "arabic": "الْمُتَعَالِي",
      "name": "El-Müteâlî",
      "meaning": "Noksanlıklardan yüce olan.",
    },
    {
      "arabic": "الْبَرُّ",
      "name": "El-Berr",
      "meaning": "İyiliği ve ihsanı bol olan.",
    },
    {
      "arabic": "التَّوَّابُ",
      "name": "Et-Tevvâb",
      "meaning": "Tövbeleri kabul eden.",
    },
    {
      "arabic": "الْمُنْتَقِمُ",
      "name": "El-Müntekim",
      "meaning": "Suçluları adaletiyle cezalandıran.",
    },
    {
      "arabic": "الْعَفُوُّ",
      "name": "El-Afüvv",
      "meaning": "Affeden, günahları silen.",
    },
    {
      "arabic": "الرَّؤُوفُ",
      "name": "Er-Raûf",
      "meaning": "Çok şefkatli ve merhametli.",
    },
    {
      "arabic": "مَالِكُ الْمُلْكِ",
      "name": "Mâlikü'l-Mülk",
      "meaning": "Mülkün ebedi sahibi.",
    },
    {
      "arabic": "ذُو الْجَلَالِ وَالْإِكْرَامِ",
      "name": "Zü'l-Celâli ve'l-İkrâm",
      "meaning": "Büyüklük, azamet ve ikram sahibi.",
    },
    {
      "arabic": "الْمُقْسِطُ",
      "name": "El-Muksit",
      "meaning": "Adaletle hükmeden.",
    },
    {
      "arabic": "الْجَامِعُ",
      "name": "El-Câmi",
      "meaning": "İstediğini istediği zaman toplayan.",
    },
    {
      "arabic": "الْغَنِيُّ",
      "name": "El-Ganiyy",
      "meaning": "Çok zengin, hiçbir şeye muhtaç olmayan.",
    },
    {
      "arabic": "الْمُغْنِي",
      "name": "El-Muğnî",
      "meaning": "Dilediğini zengin eden.",
    },
    {
      "arabic": "الْمَانِعُ",
      "name": "El-Mâni",
      "meaning": "Bir şeyin meydana gelmesine izin vermeyen.",
    },
    {
      "arabic": "الضَّارُّ",
      "name": "Ed-Dârr",
      "meaning": "Elem ve zarar verici şeyleri yaratan.",
    },
    {
      "arabic": "النَّافِعُ",
      "name": "En-Nâfi",
      "meaning": "Fayda veren şeyleri yaratan.",
    },
    {
      "arabic": "النُّورُ",
      "name": "En-Nûr",
      "meaning": "Alemleri nurlandıran.",
    },
    {
      "arabic": "الْهَادِي",
      "name": "El-Hâdî",
      "meaning": "Hidayet veren, doğru yolu gösteren.",
    },
    {
      "arabic": "الْبَدِيعُ",
      "name": "El-Bedî",
      "meaning": "Eşi ve benzeri olmayan güzellikler yaratan.",
    },
    {
      "arabic": "الْبَاقِي",
      "name": "El-Bâkî",
      "meaning": "Varlığının sonu olmayan, ebedi.",
    },
    {
      "arabic": "الْوَارِثُ",
      "name": "El-Vâris",
      "meaning": "Her şeyin asıl sahibi.",
    },
    {
      "arabic": "الرَّشِيدُ",
      "name": "Er-Reşîd",
      "meaning": "Doğru yolu gösteren, irşad eden.",
    },
    {
      "arabic": "الصَّبُورُ",
      "name": "Es-Sabûr",
      "meaning": "Ceza vermede acele etmeyen, çok sabırlı.",
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
          "Esma-ül Hüsna",
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
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Yan yana 2 tane
          childAspectRatio: 0.85, // Kartın boy/en oranı
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: esmalar.length,
        itemBuilder: (context, index) {
          final esma = esmalar[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arapça Yazı (Büyük ve Altın)
                Text(
                  esma["arabic"]!,
                  style: GoogleFonts.amiri(
                    color: AppTheme.premiumGold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Türkçe İsim
                Text(
                  esma["name"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Anlamı (Kısa)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    esma["meaning"]!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Paylaş Butonu (Ufak)
                GestureDetector(
                  onTap: () {
                    Share.share(
                      "${esma['name']} (${esma['arabic']}): ${esma['meaning']} - Nûr AI",
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.sageGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      PhosphorIcons.shareNetwork(),
                      size: 14,
                      color: AppTheme.sageGreen,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
