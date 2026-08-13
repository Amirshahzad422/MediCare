import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Live call-room state for a video consultation.
///
/// Both the patient and the doctor open the SAME call room (keyed by the
/// appointment id), so both sides see the same live status and chat in
/// real time. True peer-to-peer media would use Agora/WebRTC on top of
/// this signaling state.
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

  /// Creates the call room document (if missing) from an appointment.
  Future<String> ensureCallRoom(Map<String, dynamic> appointment) async {
    final callId = (appointment['callId'] as String?) ?? (appointment['id'] as String);
    final callRef = _callRef(callId);

    final snapshot = await callRef.get();
    if (!snapshot.exists) {
      await callRef.set({
        'appointmentId': appointment['id'],
        'doctorName': appointment['doctorName'] ?? 'Doctor',
        'doctorPhoto': appointment['doctorPhoto'] ?? '',
        'patientName': appointment['patientName'] ?? 'Patient',
        'patientPhoto': appointment['patientPhoto'] ?? '',
        'specialty': appointment['specialty'] ?? 'General Physician',
        'status': statusScheduled,
        'doctorJoined': false,
        'patientJoined': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return callId;
  }

  /// Marks the caller as joined. When both sides are in, the call goes
  /// from `ringing` to `connected`.
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

  /// Live snapshot of the call room.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String callId) {
    return _callRef(callId).snapshots();
  }

  Future<Map<String, dynamic>?> getCall(String callId) async {
    final snapshot = await _callRef(callId).get();
    return snapshot.data();
  }

  /// Ends the call and records who ended it.
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
