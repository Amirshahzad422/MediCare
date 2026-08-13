import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      final querySnapshot = await _db
          .collection('medicines')
          .orderBy('name', descending: false)
          .get();
      return querySnapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<MedicineModel>> watchMedicines() {
    return _db
        .collection('medicines')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}