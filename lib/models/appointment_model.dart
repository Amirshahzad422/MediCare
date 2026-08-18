import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentStatus {
  static const int upcoming = 1;
  static const int past = 2;
  static const int cancelled = 3;
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String date;
  final String slot;
  final String type;
  final double amount;
  final int consultationDuration;
  final int status;
  final DateTime? createdAt;
  final bool canBeCancelled;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.date,
    required this.slot,
    required this.type,
    required this.amount,
    required this.consultationDuration,
    required this.status,
    this.createdAt,
    this.canBeCancelled = true,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    final rawStatus = data['status'];
    final parsedStatus = rawStatus is int 
        ? rawStatus 
        : (int.tryParse(rawStatus?.toString() ?? '') ?? AppointmentStatus.upcoming);

    return AppointmentModel(
      id: documentId,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      date: data['date'] ?? '',
      slot: data['slot'] ?? '',
      type: data['type'] ?? 'Video Call',
      amount: (data['amount'] ?? 0).toDouble(),
      consultationDuration: (data['consultationDuration'] ?? 30) as int,
      status: parsedStatus,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      canBeCancelled: data['canBeCancelled'] ?? (parsedStatus == AppointmentStatus.upcoming),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'date': date,
      'slot': slot,
      'type': type,
      'amount': amount,
      'consultationDuration': consultationDuration,
      'status': status,
      'canBeCancelled': canBeCancelled,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}