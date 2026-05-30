// lib/core/models/quran_data.dart

class QuranSurah {
  final int number;
  final SurahName name;
  final RevelationPlace revelationPlace;
  final int versesCount;
  final int wordsCount;
  final int lettersCount;
  final List<Verse> verses;
  final List<AudioReciter> audio;

  QuranSurah({
    required this.number,
    required this.name,
    required this.revelationPlace,
    required this.versesCount,
    required this.wordsCount,
    required this.lettersCount,
    required this.verses,
    required this.audio,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      number: json['number'],
      name: SurahName.fromJson(json['name']),
      revelationPlace: RevelationPlace.fromJson(json['revelation_place']),
      versesCount: json['verses_count'],
      wordsCount: json['words_count'],
      lettersCount: json['letters_count'],
      verses: (json['verses'] as List).map((v) => Verse.fromJson(v)).toList(),
      audio:
          (json['audio'] as List).map((a) => AudioReciter.fromJson(a)).toList(),
    );
  }
}

class SurahName {
  final String ar;
  final String en;
  final String transliteration;
  final String? tr;

  SurahName({
    required this.ar,
    required this.en,
    required this.transliteration,
    this.tr,
  });

  factory SurahName.fromJson(Map<String, dynamic> json) {
    return SurahName(
      ar: json['ar'],
      en: json['en'],
      transliteration: json['transliteration'],
      tr: json['tr'],
    );
  }
}

class RevelationPlace {
  final String ar;
  final String en;
  final String? trValue;

  RevelationPlace({required this.ar, required this.en, this.trValue});

  factory RevelationPlace.fromJson(Map<String, dynamic> json) {
    return RevelationPlace(
      ar: json['ar'],
      en: json['en'],
      trValue: json['tr'],
    );
  }

  // Türkçe'ye çevir
  String get tr {
    if (trValue != null) return trValue!;
    
    if (en.toLowerCase() == 'meccan') {
      return 'Mekke';
    } else if (en.toLowerCase() == 'medinan') {
      return 'Medine';
    }
    return en; // fallback
  }
}

class Verse {
  final int number;
  final VerseText text;
  final int juz;
  final int page;
  final bool sajda;

  Verse({
    required this.number,
    required this.text,
    required this.juz,
    required this.page,
    required this.sajda,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    // sajda alanı bazen bool, bazen obje olabiliyor
    bool hasSajda = false;
    final sajdaValue = json['sajda'];

    if (sajdaValue is bool) {
      hasSajda = sajdaValue;
    } else if (sajdaValue is Map) {
      // Obje ise, recommended veya obligatory kontrolü yap
      hasSajda =
          sajdaValue['recommended'] == true || sajdaValue['obligatory'] == true;
    }

    return Verse(
      number: json['number'],
      text: VerseText.fromJson(json['text']),
      juz: json['juz'],
      page: json['page'],
      sajda: hasSajda,
    );
  }
}

class VerseText {
  final String ar;
  final String en;
  final String? tr; // Türkçe meal

  VerseText({required this.ar, required this.en, this.tr});

  factory VerseText.fromJson(Map<String, dynamic> json) {
    return VerseText(
      ar: json['ar'],
      en: json['en'],
      tr: json['tr'],
    );
  }
}

class AudioReciter {
  final int id;
  final ReciterName reciter;
  final Rewaya rewaya;
  final String server;
  final String link;

  AudioReciter({
    required this.id,
    required this.reciter,
    required this.rewaya,
    required this.server,
    required this.link,
  });

  factory AudioReciter.fromJson(Map<String, dynamic> json) {
    return AudioReciter(
      id: json['id'],
      reciter: ReciterName.fromJson(json['reciter']),
      rewaya: Rewaya.fromJson(json['rewaya']),
      server: json['server'],
      link: json['link'],
    );
  }
}

class ReciterName {
  final String ar;
  final String en;

  ReciterName({required this.ar, required this.en});

  factory ReciterName.fromJson(Map<String, dynamic> json) {
    return ReciterName(
      ar: json['ar'],
      en: json['en'],
    );
  }
}

class Rewaya {
  final String ar;
  final String en;

  Rewaya({required this.ar, required this.en});

  factory Rewaya.fromJson(Map<String, dynamic> json) {
    return Rewaya(
      ar: json['ar'],
      en: json['en'],
    );
  }
}
