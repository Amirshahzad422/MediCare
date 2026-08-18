import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
        await user.updateDisplayName(name);
        
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        await updateFCMToken(user.uid);
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
      if (result.user != null) {
        await updateFCMToken(result.user!.uid);
      }
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateFCMToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
      }
    }
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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      User? user = result.user;

      if (user != null) {
        try {
          await user.linkWithCredential(credential);
        } catch (e) {
          await user.delete();
          rethrow;
        }

        await user.updateDisplayName(data['name']);
        
        UserModel newUser = UserModel(
          uid: user.uid,
          name: data['name'],
          email: data['email'],
          phone: data['phone'],
          role: data['role'],
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        await updateFCMToken(user.uid);
      }
      return user;
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw Exception('Registration failed.');
    }
  }
}