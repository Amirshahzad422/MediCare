import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/doctor_service.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import 'auth_provider.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());

final doctorsListProvider = FutureProvider<List<DoctorModel>>((ref) async {
  final doctorService = ref.read(doctorServiceProvider);
  try {
    final doctors = await doctorService.getAllDoctors();
    return doctors;
  } catch (e, stack) {
    return [];
  }
});

final doctorByIdProvider = FutureProvider.family<DoctorModel?, String>((ref, doctorId) async {
  final doctorService = ref.read(doctorServiceProvider);
  try {
    return await doctorService.getDoctorById(doctorId);
  } catch (e) {
    return null;
  }
});

final doctorAppointmentsProvider =
StreamProvider.autoDispose.family<List<AppointmentModel>, String>((ref, doctorId) {
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
    return AppointmentModel.fromMap(doc.data(), doc.id);
  }).toList());
});

final patientAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
    return AppointmentModel.fromMap(doc.data(), doc.id);
  }).toList());
});