class StudyDeck {
  final String id;
  final String title;
  final String category; // '657_dmk', 'kik', 'medical'

  StudyDeck({
    required this.id,
    required this.title,
    required this.category,
  });

  // Json dönüştürücüleri (.NET API uyumluluğu için)
  factory StudyDeck.fromJson(Map<String, dynamic> json) {
    return StudyDeck(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
    };
  }

  static List<StudyDeck> get defaultDecks => [
    StudyDeck(id: "deck_dmk", title: "657 Sayılı DMK - Temel Hükümler", category: "657_dmk"),
    StudyDeck(id: "deck_kik", title: "Kamu İhale Kanunu - Usuller ve Süreler", category: "kik"),
    StudyDeck(id: "deck_med", title: "Tıbbi Sekreterlik - Terimler & Kısaltmalar", category: "medical"),
  ];
}
