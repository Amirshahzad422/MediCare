import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String dateOfBirth;
  final String gender;
  final String photo;
  final int age;
  final DateTime? createdAt;

  PatientModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.photo = '',
    required this.age,
    this.createdAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      photo: map['photo'] ?? '',
      age: map['age'] ?? 0,
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'photo': photo,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}