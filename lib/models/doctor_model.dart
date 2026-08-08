class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String city;
  final double fee;
  final int experience;
  final double rating;
  final String bio;
  final String photo;
  final List<String> slots;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.city,
    required this.fee,
    required this.experience,
    required this.rating,
    required this.bio,
    required this.photo,
    required this.slots,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DoctorModel(
      id: documentId,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      city: data['city'] ?? '',
      fee: (data['fee'] ?? 0).toDouble(),
      experience: (data['experience'] ?? 0) as int,
      rating: (data['rating'] ?? 0).toDouble(),
      bio: data['bio'] ?? '',
      photo: data['photo'] ?? '',
      slots: (data['slots'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}