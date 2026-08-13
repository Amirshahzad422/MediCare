import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import 'auth_provider.dart';

final appointmentsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  
  final profile = ref.watch(userProfileProvider).value;
  if (profile == null) return const Stream.empty();

  Query query = FirebaseFirestore.instance.collection('appointments');
  
  if (profile.role == 2) {
    // If doctor, show appointments where they are the doctor
    query = query.where('doctorId', isEqualTo: user.uid);
  } else {
    // If patient, show appointments where they are the patient
    query = query.where('patientId', isEqualTo: user.uid);
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

final bookedSlotsProvider = StreamProvider.family<List<String>, String>((ref, arg) {
  final parts = arg.split('_');
  if (parts.length < 2) return Stream.value([]);
  
  final doctorId = parts[0];
  final date = parts[1];

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorId)
      .where('date', isEqualTo: date)
      .where('status', whereIn: [
        AppointmentStatus.pending,
        AppointmentStatus.accepted,
        AppointmentStatus.rescheduled
      ])
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()['slot'] as String).toList();
      });
});

String formatDateKey(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
