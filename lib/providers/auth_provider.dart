import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (doc.exists) {
    return UserModel.fromMap(doc.data()!, user.uid);
  }

  return UserModel(
    uid: user.uid,
    name: user.displayName ?? '',
    email: user.email ?? '',
    role: 1,
  );
});
