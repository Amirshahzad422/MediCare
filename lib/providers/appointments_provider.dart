import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import 'auth_provider.dart';

final appointmentsStreamProvider = StreamProvider.autoDispose<List<AppointmentModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return Stream.value([]);

      Query query = FirebaseFirestore.instance.collection('appointments');
      
      if (profile.role == 2) {
        query = query.where('doctorId', isEqualTo: user.uid);
      } else {
        query = query.where('patientId', isEqualTo: user.uid);
      }

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AppointmentModel.fromMap(data, doc.id);
        }).toList();
        return list;
      });
    },
    loading: () {
      final controller = StreamController<List<AppointmentModel>>();
      ref.onDispose(() => controller.close());
      return controller.stream;
    },
    error: (err, stack) {
      return Stream.value([]);
    },
  );
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
      .where('status', isEqualTo: 1)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()['slot'] as String).toList();
      });
});

String formatDateKey(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
