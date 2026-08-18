import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  final String name;
  final String address;
  final String dateOfBirth;
  final String gender;
  final int age;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientModel({
    required this.id,
    required this.name,
    this.address = '',
    this.dateOfBirth = '',
    this.gender = '',
    required this.age,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'age': age,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}