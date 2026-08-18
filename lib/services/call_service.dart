import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class CallChatMessage {
  final String id;
  final String senderRole;
  final String senderName;
  final String text;
  final DateTime? at;

  CallChatMessage({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.text,
    this.at,
  });

  factory CallChatMessage.fromMap(Map<String, dynamic> data, String documentId) {
    return CallChatMessage(
      id: documentId,
      senderRole: data['senderRole'] ?? 'patient',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      at: (data['at'] as dynamic)?.toDate(),
    );
  }
}


class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String statusScheduled = 'scheduled';
  static const String statusRinging = 'ringing';
  static const String statusConnected = 'connected';
  static const String statusEnded = 'ended';

  DocumentReference<Map<String, dynamic>> _callRef(String callId) =>
      _db.collection('calls').doc(callId);

  CollectionReference<Map<String, dynamic>> _messagesRef(String callId) =>
      _callRef(callId).collection('messages');

  Future<String> ensureCallRoom(AppointmentModel appointment, {String? callIdOverride}) async {
    final callId = callIdOverride ?? appointment.id;
    final callRef = _callRef(callId);

    final snapshot = await callRef.get();
    if (!snapshot.exists) {
      final patientDoc = await _db.collection('users').doc(appointment.patientId).get();
      final doctorDoc = await _db.collection('doctors').doc(appointment.doctorId).get();

      await callRef.set({
        'appointmentId': appointment.id,
        'doctorName': doctorDoc.data()?['name'] ?? 'Doctor',
        'doctorPhoto': doctorDoc.data()?['photo'] ?? '',
        'patientName': patientDoc.data()?['name'] ?? appointment.patientName,
        'patientPhoto': patientDoc.data()?['photo'] ?? '',
        'specialty': doctorDoc.data()?['specialty'] ?? 'General Physician',
        'status': statusScheduled,
        'doctorJoined': false,
        'patientJoined': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return callId;
  }

  Future<void> joinCall(
    String callId, {
    required bool isDoctor,
    required String name,
  }) async {
    final callRef = _callRef(callId);
    final snapshot = await callRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data();
    final alreadyJoined = isDoctor
        ? (data?['doctorJoined'] ?? false)
        : (data?['patientJoined'] ?? false);

    if (alreadyJoined) return;

    final update = <String, dynamic>{
      if (isDoctor) 'doctorJoined': true else 'patientJoined': true,
      if (isDoctor) 'doctorName': name else 'patientName': name,
      'lastJoinAt': FieldValue.serverTimestamp(),
    };

    final doctorJoined = isDoctor ? true : (data?['doctorJoined'] ?? false);
    final patientJoined = isDoctor ? (data?['patientJoined'] ?? false) : true;

    if (doctorJoined && patientJoined) {
      update['status'] = statusConnected;
      update['startedAt'] = FieldValue.serverTimestamp();
    } else {
      update['status'] = statusRinging;
    }

    await callRef.update(update);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String callId) {
    return _callRef(callId).snapshots();
  }

  Future<Map<String, dynamic>?> getCall(String callId) async {
    final snapshot = await _callRef(callId).get();
    return snapshot.data();
  }

  Future<void> endCall(String callId, {required String endedBy}) async {
    final callRef = _callRef(callId);
    final snapshot = await callRef.get();
    if (!snapshot.exists) return;
    final status = snapshot.data()?['status'];
    if (status == statusEnded) return;
    await callRef.update({
      'status': statusEnded,
      'endedAt': FieldValue.serverTimestamp(),
      'endedBy': endedBy,
    });
  }

  Stream<List<CallChatMessage>> watchMessages(String callId) {
    return _messagesRef(callId)
        .orderBy('at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(String callId, String role, String name, String text) {
    return _messagesRef(callId).add({
      'senderRole': role,
      'senderName': name,
      'text': text,
      'at': FieldValue.serverTimestamp(),
    });
  }
}
