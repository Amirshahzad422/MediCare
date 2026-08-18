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

final prescriptionsForDoctorProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, doctorId) {
  return FirebaseFirestore.instance
      .collection('prescriptions')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots()
      .asyncMap((snapshot) async {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    for (var p in list) {
      final patientId = p['patientId'] as String?;
      if (patientId != null) {
        try {
          final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(patientId).get();
          if (patientDoc.exists) {
            final pData = patientDoc.data()!;
            p['patientAge'] = pData['age']?.toString() ?? p['patientAge'];
            p['patientGender'] = pData['gender'] ?? p['patientGender'];
            
            if (pData['name'] != null && pData['name'].toString().isNotEmpty) {
              p['patientName'] = pData['name'];
            }
          } else {
             final userDoc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
             if (userDoc.exists) {
                final uData = userDoc.data()!;
                if (uData['name'] != null && uData['name'].toString().isNotEmpty) {
                  p['patientName'] = uData['name'];
                }
             }
          }
        } catch (_) {}
      }
    }

    list.sort((a, b) {
      final aAt = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      final bAt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
      return bAt.compareTo(aAt);
    });
    return list;
  });
});