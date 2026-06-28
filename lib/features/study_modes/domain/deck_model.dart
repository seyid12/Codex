import 'package:cloud_firestore/cloud_firestore.dart';

class DeckModel {
  final String id;
  final String title;
  final String category;
  final String creatorId;
  final String? classId;
  final DateTime createdAt;

  DeckModel({
    required this.id,
    required this.title,
    required this.category,
    required this.creatorId,
    this.classId,
    required this.createdAt,
  });

  factory DeckModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DeckModel(
      id: documentId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      creatorId: map['creatorId'] ?? '',
      classId: map['classId'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'creatorId': creatorId,
      'classId': classId,
      'createdAt': createdAt,
    };
  }
}
