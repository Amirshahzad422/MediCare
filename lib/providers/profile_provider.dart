import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/profile_service.dart';
import '../models/doctor_model.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

final favouritesProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const [];
  final service = ref.watch(profileServiceProvider);
  return service.getFavourites(user.uid);
});

final userDocProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final db = FirebaseFirestore.instance;
  final userDoc = await db.collection('users').doc(user.uid).get();
  if (!userDoc.exists) return null;

  Map<String, dynamic> data = userDoc.data()!;

  if (data['role'] == 2) {
    final doctorDoc = await db.collection('doctors').doc(user.uid).get();
    if (doctorDoc.exists) {
      data.addAll(doctorDoc.data()!);
    }
  } else if (data['role'] == 1) {
    final patientDoc = await db.collection('patients').doc(user.uid).get();
    if (patientDoc.exists) {
      data.addAll(patientDoc.data()!);
    }
  }
  return data;
});

final doctorProfileProvider = FutureProvider<DoctorModel?>((ref) async {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
  if (!doc.exists) return null;
  try {
    return DoctorModel.fromMap(doc.data()!, doc.id);
  } catch (e) {
    return null;
  }
});

final patientByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, patientId) async {
  final db = FirebaseFirestore.instance;
  final userDoc = await db.collection('users').doc(patientId).get();
  if (!userDoc.exists) return null;
  
  final Map<String, dynamic> data = userDoc.data()!;
  final patientDoc = await db.collection('patients').doc(patientId).get();
  if (patientDoc.exists) {
    data.addAll(patientDoc.data()!);
  }
  return data;
});

final basicUserByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final db = FirebaseFirestore.instance;
  final userDoc = await db.collection('users').doc(uid).get();
  return userDoc.exists ? userDoc.data() : null;
});