import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Starting Quran translation update...');

  final baseUrl = 'http://api.alquran.cloud/v1/surah';
  final assetsDir = Directory('assets/quran/surah');

  if (!await assetsDir.exists()) {
    print('Error: Assets directory not found at ${assetsDir.path}');
    return;
  }


  // Turkish Surah Names Map
  const turkishSurahNames = {
    1: "Fâtiha", 2: "Bakara", 3: "Âl-i İmrân", 4: "Nisâ", 5: "Mâide", 6: "En'âm", 7: "A'râf", 8: "Enfâl", 9: "Tevbe", 10: "Yûnus",
    11: "Hûd", 12: "Yûsuf", 13: "Ra'd", 14: "İbrahim", 15: "Hicr", 16: "Nahl", 17: "İsrâ", 18: "Kehf", 19: "Meryem", 20: "Tâhâ",
    21: "Enbiyâ", 22: "Hac", 23: "Mü'minûn", 24: "Nûr", 25: "Furkân", 26: "Şuarâ", 27: "Neml", 28: "Kasas", 29: "Ankebût", 30: "Rûm",
    31: "Lokmân", 32: "Secde", 33: "Ahzâb", 34: "Sebe'", 35: "Fâtır", 36: "Yâsîn", 37: "Sâffât", 38: "Sâd", 39: "Zümer", 40: "Mü'min",
    41: "Fussilet", 42: "Şûrâ", 43: "Zuhruf", 44: "Duhân", 45: "Câsiye", 46: "Ahkâf", 47: "Muhammed", 48: "Fetih", 49: "Hucurât", 50: "Kâf",
    51: "Zâriyât", 52: "Tûr", 53: "Necm", 54: "Kamer", 55: "Rahmân", 56: "Vâkıa", 57: "Hadîd", 58: "Mücâdele", 59: "Haşr", 60: "Mümtehine",
    61: "Saff", 62: "Cuma", 63: "Münâfikûn", 64: "Teğâbün", 65: "Talâk", 66: "Tahrîm", 67: "Mülk", 68: "Kalem", 69: "Hâkka", 70: "Meâric",
    71: "Nûh", 72: "Cin", 73: "Müzzemmil", 74: "Müddessir", 75: "Kıyâme", 76: "İnsân", 77: "Mürselât", 78: "Nebe'", 79: "Nâziât", 80: "Abese",
    81: "Tekvîr", 82: "İnfitâr", 83: "Mutaffifîn", 84: "İnşikâk", 85: "Burûc", 86: "Târık", 87: "A'lâ", 88: "Gâşiye", 89: "Fecr", 90: "Beled",
    91: "Şems", 92: "Leyl", 93: "Duhâ", 94: "İnşirâh", 95: "Tîn", 96: "Alak", 97: "Kadir", 98: "Beyyine", 99: "Zilzâl", 100: "Âdiyât",
    101: "Kâria", 102: "Tekâsür", 103: "Asr", 104: "Hümeze", 105: "Fîl", 106: "Kureyş", 107: "Mâûn", 108: "Kevser", 109: "Kâfirûn", 110: "Nasr",
    111: "Tebbet", 112: "İhlâs", 113: "Felâk", 114: "Nâs"
  };

  // Loop through all 114 Surahs
  for (int i = 1; i <= 114; i++) {
    try {
      print('Processing Surah $i...');

      // 1. Fetch Turkish translation
      final response = await http.get(Uri.parse('$baseUrl/$i/tr.diyanet'));

      if (response.statusCode != 200) {
        print('Error fetching Surah $i: ${response.statusCode}');
        continue;
      }

      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'];
      final turkishVerses = data['ayahs'] as List;

      // 2. Read existing local JSON
      final file = File('${assetsDir.path}/surah_$i.json');
      if (!await file.exists()) {
        print('Warning: Local file for Surah $i not found.');
        continue;
      }

      final content = await file.readAsString();
      final localJson = json.decode(content);
      
      // 3. Update Name
      if (localJson['name'] != null) {
          // Use the hardcoded map for Turkish names
          localJson['name']['tr'] = turkishSurahNames[i];
      }

      // 4. Merge Turkish text into verses
      final List<dynamic> localVerses = localJson['verses'];

      if (localVerses.length != turkishVerses.length) {
        print('Mismatch in verse count for Surah $i! Local: ${localVerses.length}, Remote: ${turkishVerses.length}');
        // Proceed with caution or skip? Let's try to match by number.
      }

      for (var localVerse in localVerses) {
        final number = localVerse['number']; // this is relative number usually in local? No, standard is 1..N
        // The API returns 'numberInSurah'.
        
        final remoteVerse = turkishVerses.firstWhere(
          (v) => v['numberInSurah'] == number,
          orElse: () => null,
        );

        if (remoteVerse != null) {
           if (localVerse['text'] == null) {
             localVerse['text'] = {};
           }
           localVerse['text']['tr'] = remoteVerse['text'];
        }
      }

      // 5. Save back to file
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(localJson));
      print('Saved Surah $i.');
      
      // Be nice to the API
      await Future.delayed(Duration(milliseconds: 200)); 

    } catch (e) {
      print('Exception processing Surah $i: $e');
    }
  }

  print('Update complete.');
}
