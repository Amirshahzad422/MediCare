import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final prescriptionsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('prescriptions')
      .where('patientId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    list.sort((a, b) {
      final aAt = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      final bAt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      return bAt.compareTo(aAt);
    });
    return list;
  });
});

/// Prescriptions issued by one doctor (Doctor Dashboard → Records tab).
final prescriptionsForDoctorProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, doctorId) {
  return FirebaseFirestore.instance
      .collection('prescriptions')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    list.sort((a, b) {
      final aAt = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      final bAt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      return bAt.compareTo(aAt);
    });
    return list;
  });
});