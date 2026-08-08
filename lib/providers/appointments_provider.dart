import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final appointmentsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

final bookedSlotsProvider = StreamProvider.family<List<String>, String>((ref, arg) {
  final parts = arg.split('_');
  final doctorName = parts[0];
  final date = parts[1];
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorName', isEqualTo: doctorName)
      .where('date', isEqualTo: date)
      .where('status', isEqualTo: 'upcoming')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()['slot'] as String).toList();
  });
});