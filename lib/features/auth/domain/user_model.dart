import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "Teacher" or "Student"
  final int streak;
  final int totalXp;
  final int level;
  final DateTime lastActiveAt;
  final List<String> classIds;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.streak,
    required this.totalXp,
    required this.level,
    required this.lastActiveAt,
    required this.classIds,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Student',
      streak: map['streak']?.toInt() ?? 0,
      totalXp: map['totalXp']?.toInt() ?? 0,
      level: map['level']?.toInt() ?? 1,
      lastActiveAt: map['lastActiveAt'] is Timestamp
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : DateTime.now(),
      classIds: List<String>.from(map['classIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'streak': streak,
      'totalXp': totalXp,
      'level': level,
      'lastActiveAt': lastActiveAt,
      'classIds': classIds,
    };
  }
}
