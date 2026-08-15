import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

final appointmentsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('--- appointmentsStreamProvider: user is null');
    return Stream.value([]);
  }
  
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      print('--- appointmentsStreamProvider: user=${user.uid}, profile=$profile');
      if (profile == null) return Stream.value([]);

      Query query = FirebaseFirestore.instance.collection('appointments');
      
      if (profile.role == 2) {
        print('--- appointmentsStreamProvider: filtering for doctorId=${user.uid}');
        query = query.where('doctorId', isEqualTo: user.uid);
      } else {
        print('--- appointmentsStreamProvider: filtering for patientId=${user.uid}');
        query = query.where('patientId', isEqualTo: user.uid);
      }

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        print('--- appointmentsStreamProvider: returned ${list.length} appointments');
        return list;
      });
    },
    loading: () {
      print('--- appointmentsStreamProvider: profile is loading, returning pending stream');
      final controller = StreamController<List<Map<String, dynamic>>>();
      ref.onDispose(() => controller.close());
      return controller.stream;
    },
    error: (err, stack) {
      print('--- appointmentsStreamProvider: profile error=$err');
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
