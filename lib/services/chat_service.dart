import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? at;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.at,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatMessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      at: (data['at'] as dynamic)?.toDate(),
    );
  }
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Deterministic thread key shared by patient & doctor for a consultation.
  static String threadKey(String uid, String doctorName) {
    final base = '$uid-$doctorName'.toLowerCase();
    return base.replaceAll(RegExp(r'[^a-z0-9]'), '-');
  }

  Stream<List<ChatMessageModel>> watchMessages(String threadKey) {
    return _db
        .collection('chats')
        .doc(threadKey)
        .collection('messages')
        .orderBy('at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(String threadKey, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('chats').doc(threadKey).collection('messages').add({
      'senderId': user.uid,
      'senderName': user.displayName ?? (user.email ?? 'User'),
      'text': text,
      'at': FieldValue.serverTimestamp(),
    });
  }
}