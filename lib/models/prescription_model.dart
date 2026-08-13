class PrescriptionMed {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String notes;

  PrescriptionMed({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.notes = '',
  });

  factory PrescriptionMed.fromMap(Map<String, dynamic> data) {
    return PrescriptionMed(
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      duration: data['duration'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'notes': notes,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String doctorPhoto;
  final String date;
  final String diagnosis;
  final List<PrescriptionMed> medicines;
  final String status;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.doctorPhoto,
    required this.date,
    required this.diagnosis,
    required this.medicines,
    this.status = 'active',
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PrescriptionModel(
      id: documentId,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'] ?? '',
      doctorPhoto: data['doctorPhoto'] ?? '',
      date: data['date'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      medicines: (data['medicines'] as List?)
              ?.map((e) => PrescriptionMed.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'doctorPhoto': doctorPhoto,
      'date': date,
      'diagnosis': diagnosis,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'status': status,
    };
  }
}