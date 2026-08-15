import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required int role,
  }) async {
    try {
      // Check if phone number is already registered
      final querySnapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'phone-already-in-use',
          message: 'This phone number is already registered. Please login instead.',
        );
      }
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Update the display name in Firebase Auth
        await user.updateDisplayName(name);
        
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      return null;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<int> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') ?? 1;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }

  Future<String?> getEmailFromPhone(String phone) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> isPhoneRegistered(String phone, {String? excludeUid}) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(2)
          .get();
          
      if (querySnapshot.docs.isEmpty) return false;
      
      if (excludeUid != null) {
        // If there's only one and it belongs to the current user, it's fine.
        final docs = querySnapshot.docs.where((doc) => doc.id != excludeUid).toList();
        return docs.isNotEmpty;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isEmailRegistered(String email, {String? excludeUid}) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(2)
          .get();
          
      if (querySnapshot.docs.isEmpty) return false;
      
      if (excludeUid != null) {
        final docs = querySnapshot.docs.where((doc) => doc.id != excludeUid).toList();
        return docs.isNotEmpty;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<User?> registerWithVerifiedPhone(PhoneAuthCredential credential, Map<String, dynamic> data) async {
    try {
      // 1. Create User with Email and Password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      User? user = result.user;

      if (user != null) {
        // 2. Link Phone Credential
        try {
          await user.linkWithCredential(credential);
        } catch (e) {
          // If linking fails, clean up the created user to prevent orphaned accounts
          await user.delete();
          rethrow;
        }

        // 3. Update Display Name and Save to Firestore
        await user.updateDisplayName(data['name']);
        
        UserModel newUser = UserModel(
          uid: user.uid,
          name: data['name'],
          email: data['email'],
          phone: data['phone'],
          role: data['role'],
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw Exception('Registration failed.');
    }
  }
}