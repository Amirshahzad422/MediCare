
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String doctorId;
  final String patientName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientName': patientName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}