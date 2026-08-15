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
  final int consultationDuration;
  final String qualifications;
  final String gender;
  final bool availableToday;
  final int bookedCount;
  final List<Map<String, dynamic>> reviews;
  final DateTime? createdAt;
  final bool isOnboardingComplete;
  final List<String> availableDays;
  final int businessStartHour;
  final int businessEndHour;
  final String contact;

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
    this.slots = const [],
    this.consultationDuration = 30,
    this.qualifications = '',
    this.gender = 'Any',
    this.availableToday = true,
    this.bookedCount = 0,
    this.reviews = const [],
    this.createdAt,
    this.isOnboardingComplete = false,
    this.availableDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    this.businessStartHour = 8,
    this.businessEndHour = 18,
    this.contact = '',
  });

  factory DoctorModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DoctorModel(
      id: documentId,
      name: data['name'] ?? '',
      specialty: data['specialty'] ?? '',
      city: data['city'] ?? '',
      fee: (data['fee'] ?? 0).toDouble(),
      experience: data['experience'] is int ? data['experience'] : (int.tryParse(data['experience']?.toString() ?? '') ?? 0),
      rating: (data['rating'] ?? 0).toDouble(),
      bio: data['bio'] ?? '',
      photo: data['photo'] ?? '',
      slots: (data['slots'] as List?)?.map((e) => e.toString()).toList() ?? [],
      consultationDuration: (data['consultationDuration'] ?? 30) as int,
      qualifications: data['qualifications']  ?? data['credentials'] ?? '',
      gender: data['gender'] ?? 'Any',
      availableToday: data['availableToday'] ?? true,
      bookedCount: (data['bookedCount'] ?? 0) as int,
      reviews: (data['reviews'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
          const [],
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      availableDays: (data['availableDays'] as List?)?.map((e) => e.toString()).toList() ?? [],
      businessStartHour: (data['businessStartHour'] ?? 8) as int,
      businessEndHour: (data['businessEndHour'] ?? 18) as int,
      contact: data['contact'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'city': city,
      'fee': fee,
      'experience': experience,
      'rating': rating,
      'bio': bio,
      'photo': photo,
      'slots': slots,
      'consultationDuration': consultationDuration,
      'qualifications': qualifications,
      'gender': gender,
      'availableToday': availableToday,
      'bookedCount': bookedCount,
      'reviews': reviews,
      'isOnboardingComplete': isOnboardingComplete,
      'availableDays': availableDays,
      'businessStartHour': businessStartHour,
      'businessEndHour': businessEndHour,
      'contact': contact,
    };
  }
}