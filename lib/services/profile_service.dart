import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> updatePatientProfile({
    required String name,
    String phone = '',
    String address = '',
    String photo = '',
    String dateOfBirth = '',
    String gender = '',
    int age = 0,
    bool isOnboardingComplete = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final updates = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      'photo': photo,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'age': age,
      'isOnboardingComplete': isOnboardingComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      await user.updateDisplayName(name);
      if (photo.isNotEmpty) {
        await user.updatePhotoURL(photo);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDoctorProfile({
    required String name,
    required String specialty,
    required double fee,
    String city = '',
    String bio = '',
    List<String> slots = const [],
    int consultationDuration = 30,
    List<String> availableDays = const [],
    String credentials = '',
    String photo = '',
    bool availableToday = true,
    bool isOnboardingComplete = true,
    int businessStartHour = 8,   // added
    int businessEndHour = 18,    // added
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final updates = <String, dynamic>{
      'name': name,
      'specialty': specialty,
      'fee': fee,
      'city': city,
      'bio': bio,
      'slots': slots,
      'consultationDuration': consultationDuration,
      'availableDays': availableDays,
      'credentials': credentials,
      'photo': photo,
      'availableToday': availableToday,
      'isOnboardingComplete': isOnboardingComplete,
      'businessStartHour': businessStartHour,   // save
      'businessEndHour': businessEndHour,       // save
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      await _db.collection('doctors').doc(user.uid).set({
        ...updates,
        'id': user.uid,
      }, SetOptions(merge: true));

      await user.updateDisplayName(name);
      if (photo.isNotEmpty) {
        await user.updatePhotoURL(photo);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> syncDoctorAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      if (data['role'] != 2) return; // Only for doctors

      final List<String> availableDays = (data['availableDays'] as List?)?.cast<String>() ?? [];
      if (availableDays.isEmpty) return;

      final List<String> allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final String todayName = allDays[DateTime.now().weekday - 1];
      final bool shouldBeAvailable = availableDays.contains(todayName);
      final bool currentStatus = data['availableToday'] ?? false;

      if (shouldBeAvailable != currentStatus) {
        await _db.collection('users').doc(user.uid).update({'availableToday': shouldBeAvailable});
        await _db.collection('doctors').doc(user.uid).update({'availableToday': shouldBeAvailable});
      }
    } catch (e) {
      // Handle error or log
    }
  }

  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleFavourite(String doctorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();
      final favourites = (doc.data()?['favouriteDoctors'] as List?)?.cast<String>() ?? [];
      final exists = favourites.contains(doctorId);
      if (exists) {
        favourites.remove(doctorId);
      } else {
        favourites.add(doctorId);
      }
      await docRef.set({'favouriteDoctors': favourites}, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getFavourites(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return (doc.data()?['favouriteDoctors'] as List?)?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> incrementBookedCount(String doctorName) async {
    try {
      final snapshot = await _db
          .collection('doctors')
          .where('name', isEqualTo: doctorName)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return;
      final ref = snapshot.docs.first.reference;
      await ref.update({'bookedCount': FieldValue.increment(1)});
    } catch (e) {
    }
  }

  Future<bool> setDoctorAvailability(String name, bool availableToday) async {
    try {
      final doctorsSnapshot = await _db
          .collection('doctors')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (doctorsSnapshot.docs.isNotEmpty) {
        final docId = doctorsSnapshot.docs.first.id;
        await _db.collection('doctors').doc(docId).update({'availableToday': availableToday});
        await _db.collection('users').doc(docId).update({'availableToday': availableToday});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static DoctorModel? doctorFromUserDoc(String uid, Map<String, dynamic>? doc) {
    if (doc == null) return null;
    return DoctorModel(
      id: uid,
      name: doc['name'] ?? '',
      specialty: doc['specialty'] ?? 'General Physician',
      city: doc['city'] ?? '',
      fee: (doc['fee'] ?? 0).toDouble(),
      experience: (doc['experience'] ?? 5) as int,
      rating: (doc['rating'] ?? 5.0).toDouble(),
      bio: doc['bio'] ?? '',
      photo: doc['photo'] ?? 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=400',
      slots: (doc['slots'] as List?)?.map((e) => e.toString()).toList() ?? [],
      consultationDuration: (doc['consultationDuration'] ?? 30) as int,
      qualifications: doc['credentials'] ?? doc['qualifications'] ?? '',
      availableToday: doc['availableToday'] ?? false,
      availableDays: (doc['availableDays'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isOnboardingComplete: doc['isOnboardingComplete'] ?? false,
      businessStartHour: (doc['businessStartHour'] ?? 8) as int,   // added
      businessEndHour: (doc['businessEndHour'] ?? 18) as int,     // added
    );
  }
}