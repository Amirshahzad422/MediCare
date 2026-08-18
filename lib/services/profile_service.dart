import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_model.dart';
import '../models/patient_model.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> updatePatientProfile({
    required String name,
    required String email,
    String phone = '',
    String address = '',
    String photo = '',
    String gender = '',
    int age = 0,
    bool isOnboardingComplete = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userUpdates = UserModel(
      uid: user.uid,
      name: name,
      email: email,
      phone: phone,
      role: 1, // Patient
      photo: photo,
      isOnboardingComplete: isOnboardingComplete,
    ).toMap();

    final patientData = PatientModel(
      id: user.uid,
      name: name,
      address: address,
      gender: gender,
      age: age,
    ).toMap();

    try {
      await _db.collection('users').doc(user.uid).set(userUpdates, SetOptions(merge: true));
      await _db.collection('patients').doc(user.uid).set(patientData, SetOptions(merge: true));
      await user.updateDisplayName(name);
      if (photo.isNotEmpty) {
        await user.updatePhotoURL(photo);
      }
      try {
        if (user.email != email && email.isNotEmpty) {
          await user.verifyBeforeUpdateEmail(email);
        }
      } catch (e) {}
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDoctorProfile({
    required String name,
    required String email,
    required String specialty,
    required double fee,
    int experience = 0,
    String city = '',
    String bio = '',
    List<String> slots = const [],
    int consultationDuration = 30,
    List<String> availableDays = const [],
    String qualifications = '',
    String photo = '',
    String phone = '',
    bool availableToday = true,
    int businessStartHour = 8,
    int businessEndHour = 18,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doctorData = DoctorModel(
      id: user.uid,
      name: name,
      specialty: specialty,
      fee: fee,
      city: city,
      experience: experience,
      bio: bio,
      slots: slots,
      consultationDuration: consultationDuration,
      availableDays: availableDays,
      qualifications: qualifications,
      availableToday: availableToday,
      businessStartHour: businessStartHour,
      businessEndHour: businessEndHour,
      rating: 5.0, // Default rating
      bookedCount: 0,
      reviews: const [],
      gender: 'Any',
    ).toMap();

    try {
      await _db.collection('doctors').doc(user.uid).set(doctorData, SetOptions(merge: true));

      final userUpdates = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: 2, // Doctor
        photo: photo,
        isOnboardingComplete: true,
      ).toMap();
      await _db.collection('users').doc(user.uid).set(userUpdates, SetOptions(merge: true));

      await user.updateDisplayName(name);
      if (photo.isNotEmpty) {
        await user.updatePhotoURL(photo);
      }
      try {
        if (user.email != email && email.isNotEmpty) {
          await user.verifyBeforeUpdateEmail(email);
        }
      } catch (e) {}
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
      if (data['role'] != 2) return;

      final doctorDoc = await _db.collection('doctors').doc(user.uid).get();
      if (!doctorDoc.exists) return;
      
      final doctorData = doctorDoc.data()!;
      final List<String> availableDays = (doctorData['availableDays'] as List?)?.cast<String>() ?? [];
      if (availableDays.isEmpty) return;

      final List<String> allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final String todayName = allDays[DateTime.now().weekday - 1];
      final bool shouldBeAvailable = availableDays.contains(todayName);
      final bool currentStatus = doctorData['availableToday'] ?? false;

      if (shouldBeAvailable != currentStatus) {
        await _db.collection('doctors').doc(user.uid).update({'availableToday': shouldBeAvailable});
      }
    } catch (e) {}
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
      final snapshot = await _db.collection('doctors').where('name', isEqualTo: doctorName).limit(1).get();
      if (snapshot.docs.isEmpty) return;
      final ref = snapshot.docs.first.reference;
      await ref.update({'bookedCount': FieldValue.increment(1)});
    } catch (e) {}
  }

  Future<bool> setDoctorAvailability(String name, bool availableToday) async {
    try {
      final doctorsSnapshot = await _db.collection('doctors').where('name', isEqualTo: name).limit(1).get();
      if (doctorsSnapshot.docs.isNotEmpty) {
        final docId = doctorsSnapshot.docs.first.id;
        await _db.collection('doctors').doc(docId).update({'availableToday': availableToday});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


}