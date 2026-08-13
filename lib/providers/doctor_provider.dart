import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/doctor_service.dart';
import '../models/doctor_model.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());

final doctorsListProvider = FutureProvider<List<DoctorModel>>((ref) async {
  final doctorService = ref.read(doctorServiceProvider);
  try {
    final doctors = await doctorService.getAllDoctors();
    print('✅ Doctors loaded: ${doctors.length}');
    return doctors;
  } catch (e, stack) {
    print('❌ Error loading doctors: $e\n$stack');
    return [];
  }
});

final doctorByIdProvider = FutureProvider.family<DoctorModel?, String>((ref, doctorId) async {
  final doctorService = ref.read(doctorServiceProvider);
  try {
    return await doctorService.getDoctorById(doctorId);
  } catch (e) {
    print('❌ Error loading doctor $doctorId: $e');
    return null;
  }
});

final doctorAppointmentsProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>((ref, doctorName) {
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorName', isEqualTo: doctorName)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList());
});

final patientAppointmentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList());
});