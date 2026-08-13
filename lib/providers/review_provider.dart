import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getReviewsForDoctor(String doctorId) {
    return _firestore
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs.map((doc) {
        return ReviewModel.fromMap(doc.data(), doc.id);
      }).toList();
      // Sort descending by createdAt (newest first)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  Future<void> addReview({
    required String doctorId,
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final patientName = user.displayName ?? 'Anonymous Patient';
    final review = ReviewModel(
      id: '',
      doctorId: doctorId,
      patientName: patientName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('reviews').add(review.toMap());
  }
}

final doctorReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, doctorId) {
  final service = ref.watch(reviewServiceProvider);
  return service.getReviewsForDoctor(doctorId);
});