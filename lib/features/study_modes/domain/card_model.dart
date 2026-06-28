class CardModel {
  final String id;
  final String cardType; // "quiz", "flashcard", "cloze", "matching"
  final String question;
  final String answer;
  final String mnemonic; // Memory hint
  final List<String> options;
  final int correctOptionIndex;
  final String clozeText;
  final String clozeAnswer;

  CardModel({
    required this.id,
    required this.cardType,
    required this.question,
    required this.answer,
    this.mnemonic = '',
    this.options = const [],
    this.correctOptionIndex = 0,
    this.clozeText = '',
    this.clozeAnswer = '',
  });

  factory CardModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CardModel(
      id: documentId,
      cardType: map['cardType'] ?? 'flashcard',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      mnemonic: map['mnemonic'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex']?.toInt() ?? 0,
      clozeText: map['clozeText'] ?? '',
      clozeAnswer: map['clozeAnswer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardType': cardType,
      'question': question,
      'answer': answer,
      'mnemonic': mnemonic,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'clozeText': clozeText,
      'clozeAnswer': clozeAnswer,
    };
  }
}
