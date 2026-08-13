class AppointmentStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String cancelled = 'cancelled';
  static const String rescheduled = 'rescheduled';
  static const String completed = 'completed';
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
  final String status;
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
      status: data['status'] ?? AppointmentStatus.pending,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      canBeCancelled: data['canBeCancelled'] ?? (data['status'] != AppointmentStatus.accepted),
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
      'canBeCancelled': status == AppointmentStatus.accepted ? false : true,
    };
  }
}