import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

/// Loads the favourite doctor ids for the signed-in user.
final favouritesProvider = FutureProvider<List<String>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const [];
  final service = ref.watch(profileServiceProvider);
  return service.getFavourites(user.uid);
});

/// Full user doc (profile fields beyond name/email/role).
final userDocProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final service = ref.watch(profileServiceProvider);
  return service.getUserDoc(user.uid);
});