import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final querySnapshot = await _db.collection('doctors').get();
      final doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();
      doctors.sort((a, b) => b.rating.compareTo(a.rating));
      return doctors;
    } catch (e) {
      print('❌ getAllDoctors error: $e');
      return [];
    }
  }

  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      final doc = await _db.collection('doctors').doc(id).get();
      if (!doc.exists) return null;
      return DoctorModel.fromMap(doc.data() ?? {}, doc.id);
    } catch (e) {
      print('❌ getDoctorById error: $e');
      return null;
    }
  }

  Future<DoctorModel?> getDoctorByName(String name) async {
    try {
      final snapshot = await _db
          .collection('doctors')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return DoctorModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('❌ getDoctorByName error: $e');
      return null;
    }
  }
}