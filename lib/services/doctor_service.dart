import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final querySnapshot = await _db
          .collection('doctors')
          .orderBy('rating', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }
}