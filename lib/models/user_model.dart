import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int role;
  final String photo;
  final bool isOnboardingComplete;
  final DateTime? updatedAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.photo = '',
    this.isOnboardingComplete = false,
    this.updatedAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 1,
      photo: data['photo'] ?? '',
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'photo': photo,
      'isOnboardingComplete': isOnboardingComplete,
      'updatedAt': FieldValue.serverTimestamp(),
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }
}