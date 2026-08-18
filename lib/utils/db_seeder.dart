import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DbSeeder {
  static final List<Map<String, dynamic>> dummyAccounts = [
    // --- Patients (Role 1) ---
    {
      'name': 'Ali Khan',
      'email': 'ali@medicare.com',
      'password': 'password123',
      'phone': '+923001234567',
      'role': 1,
    },
    {
      'name': 'Sara Ahmed',
      'email': 'sara@medicare.com',
      'password': 'password123',
      'phone': '+923009876543',
      'role': 1,
    },
    // --- Doctors (Role 2) ---
    {
      'name': 'Dr. Anna Grace',
      'email': 'anna@medicare.com',
      'password': 'password123',
      'phone': '+12025550174',
      'role': 2,
      // Doctor specific fields:
      'specialty': 'Cardiologist',
      'city': 'New York',
      'fee': 150.0,
      'experience': 10,
      'rating': 4.9,
      'bio': 'Board-certified cardiologist with 10+ years of experience in heart care and cardiovascular research.',
      'photo': 'https://i.pravatar.cc/150?img=47',
      'slots': ['09:00 AM', '10:30 AM', '02:00 PM', '04:30 PM'],
      'consultationDuration': 30,
      'qualifications': 'MBBS, MD (Cardiology), FACC',
      'gender': 'Female',
      'availableToday': true,
      'bookedCount': 320,
      'reviews': [
        {
          'name': 'Hannah L.',
          'rating': 5,
          'comment': 'Very thorough consultation. Dr. Anna explained everything clearly.',
        }
      ],
      'isOnboardingComplete': true,
      'availableDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      'businessStartHour': 9,
      'businessEndHour': 17,
    },
    {
      'name': 'Dr. Robert Chen',
      'email': 'robert@medicare.com',
      'password': 'password123',
      'phone': '+12025550188',
      'role': 2,
      // Doctor specific fields:
      'specialty': 'Neurologist',
      'city': 'San Francisco',
      'fee': 200.0,
      'experience': 15,
      'rating': 5.0,
      'bio': 'Renowned neurologist specializing in migraine management, neuromuscular disorders, and sleep therapy.',
      'photo': 'https://i.pravatar.cc/150?img=12',
      'slots': ['09:00 AM', '11:00 AM', '03:00 PM'],
      'consultationDuration': 30,
      'qualifications': 'MBBS, DM (Neurology), FAAN',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 380,
      'reviews': [],
      'isOnboardingComplete': true,
      'availableDays': ['Monday', 'Wednesday', 'Friday'],
      'businessStartHour': 9,
      'businessEndHour': 15,
    },
  ];

  /// Creates Firebase Auth accounts and seeds Firestore following UserModel and DoctorModel.
  static Future<void> seedUsersAndDoctors() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    print("Starting seeding process...");

    for (final acc in dummyAccounts) {
      try {
        // 1. Create User in Firebase Auth
        print("Creating account for ${acc['email']}...");
        UserCredential cred;
        try {
           cred = await auth.createUserWithEmailAndPassword(
            email: acc['email'],
            password: acc['password'],
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
             print("${acc['email']} already exists. Skipping auth creation.");
             continue; // Skip if already exists
          } else {
             rethrow;
          }
        }
        
        final uid = cred.user!.uid;

        // 2. Add to 'users' collection (UserModel structure)
        await firestore.collection('users').doc(uid).set({
          'name': acc['name'],
          'email': acc['email'],
          'phone': acc['phone'],
          'role': acc['role'],
        });

        // 3. If role == 2, add to 'doctors' collection (DoctorModel structure)
        if (acc['role'] == 2) {
          await firestore.collection('doctors').doc(uid).set({
            'name': acc['name'],
            'specialty': acc['specialty'],
            'city': acc['city'],
            'fee': acc['fee'],
            'experience': acc['experience'],
            'rating': acc['rating'],
            'bio': acc['bio'],
            'photo': acc['photo'],
            'slots': acc['slots'],
            'consultationDuration': acc['consultationDuration'],
            'qualifications': acc['qualifications'],
            'gender': acc['gender'],
            'availableToday': acc['availableToday'],
            'bookedCount': acc['bookedCount'],
            'reviews': acc['reviews'],
            'createdAt': FieldValue.serverTimestamp(),
            'isOnboardingComplete': acc['isOnboardingComplete'],
            'availableDays': acc['availableDays'],
            'businessStartHour': acc['businessStartHour'],
            'businessEndHour': acc['businessEndHour'],
            'contact': acc['phone'],
          });
        }
        print("Successfully seeded ${acc['email']} (Role: ${acc['role']})");
      } catch (e) {
        print("Error seeding ${acc['email']}: $e");
      }
    }

    // Since createUser logs the user in, sign out at the end so the app state is clean.
    await auth.signOut();
    print("Seeding complete. Signed out of dummy accounts.");
  }
}