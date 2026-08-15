// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';

class DbSeeder {
  static final List<Map<String, dynamic>> dummyDoctors = [
    {
      'name': 'Dr. Anna Grace',
      'specialty': 'Cardiologist',
      'city': 'New York',
      'fee': 150.0,
      'experience': 10,
      'rating': 4.9,
      'bio': 'Board-certified cardiologist with 10+ years of experience in heart care and cardiovascular research.',
      'photo': 'https://i.pravatar.cc/150?img=47',
      'slots': ['09:00 AM', '10:30 AM', '02:00 PM', '04:30 PM'],
      'qualifications': 'MBBS, MD (Cardiology), FACC',
      'gender': 'Female',
      'availableToday': true,
      'bookedCount': 320,
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 12)),
      'reviews': [
        {
          'name': 'Hannah L.',
          'rating': 5,
          'comment': 'Very thorough consultation. Dr. Anna explained everything clearly.',
        },
        {
          'name': 'Omar S.',
          'rating': 5,
          'comment': 'Booked within minutes and felt fully heard during the video call.',
        },
      ],
    },
    {
      'name': 'Dr. Marcus Vance',
      'specialty': 'Dermatologist',
      'city': 'Los Angeles',
      'fee': 120.0,
      'experience': 8,
      'rating': 4.7,
      'bio': 'Specialist in clinical dermatology, acne treatments, and advanced skin care procedures.',
      'photo': 'https://i.pravatar.cc/150?img=11',
      'slots': ['10:00 AM', '11:00 AM', '01:00 PM', '03:00 PM'],
      'qualifications': 'MBBS, MD (Dermatology), FAAD',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 268,
      'createdAt': Timestamp.fromDate(DateTime(2025, 2, 3)),
      'reviews': [
        {
          'name': 'Sofia R.',
          'rating': 5,
          'comment': 'Great advice on my skin routine. The prescription was spot on.',
        },
      ],
    },
    {
      'name': 'Dr. Sarah Jenkins',
      'specialty': 'Pediatrician',
      'city': 'Chicago',
      'fee': 100.0,
      'experience': 12,
      'rating': 4.8,
      'bio': 'Dedicated pediatrician passionate about infant health, childhood development, and immunizations.',
      'photo': 'https://i.pravatar.cc/150?img=49',
      'slots': ['08:30 AM', '11:30 AM', '02:30 PM', '05:00 PM'],
      'qualifications': 'MBBS, MD (Pediatrics), DCH',
      'gender': 'Female',
      'availableToday': true,
      'bookedCount': 412,
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 28)),
      'reviews': [
        {
          'name': 'Ayesha R.',
          'rating': 5,
          'comment': 'Dr. Sarah is so patient with kids. My daughter loves her!',
        },
        {
          'name': 'Tom H.',
          'rating': 4,
          'comment': 'Quick response and very practical advice for my son\'s fever.',
        },
      ],
    },
    {
      'name': 'Dr. Robert Chen',
      'specialty': 'Neurologist',
      'city': 'San Francisco',
      'fee': 200.0,
      'experience': 15,
      'rating': 5.0,
      'bio': 'Renowned neurologist specializing in migraine management, neuromuscular disorders, and sleep therapy.',
      'photo': 'https://i.pravatar.cc/150?img=12',
      'slots': ['09:00 AM', '11:00 AM', '03:00 PM'],
      'qualifications': 'MBBS, DM (Neurology), FAAN',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 380,
      'createdAt': Timestamp.fromDate(DateTime(2024, 11, 9)),
      'reviews': [
        {
          'name': 'Priya N.',
          'rating': 5,
          'comment': 'Finally someone who took my migraines seriously. Life changing.',
        },
      ],
    },
    {
      'name': 'Dr. Emily Watson',
      'specialty': 'Gynecologist',
      'city': 'Boston',
      'fee': 130.0,
      'experience': 7,
      'rating': 4.6,
      'bio': 'Expert in women health, prenatal care, and reproductive wellness clinics.',
      'photo': 'https://i.pravatar.cc/150?img=34',
      'slots': ['09:30 AM', '12:00 PM', '04:00 PM'],
      'qualifications': 'MBBS, MS (OBG), MRCOG',
      'gender': 'Female',
      'availableToday': false,
      'bookedCount': 240,
      'createdAt': Timestamp.fromDate(DateTime(2025, 3, 15)),
      'reviews': [
        {
          'name': 'Elena M.',
          'rating': 5,
          'comment': 'Compassionate and professional. The prenatal consult was excellent.',
        },
      ],
    },
    {
      'name': 'Dr. Alistair Cook',
      'specialty': 'Orthopedic',
      'city': 'Houston',
      'fee': 140.0,
      'experience': 9,
      'rating': 4.8,
      'bio': 'Specializes in joint replacements, sports medicine, and bone density recovery.',
      'photo': 'https://i.pravatar.cc/150?img=68',
      'slots': ['10:00 AM', '01:00 PM', '03:30 PM'],
      'qualifications': 'MBBS, MS (Orthopedics), FICS',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 295,
      'createdAt': Timestamp.fromDate(DateTime(2025, 2, 20)),
      'reviews': [
        {
          'name': 'Marcus T.',
          'rating': 5,
          'comment': 'Great guidance for my knee recovery plan. Clear and actionable.',
        },
      ],
    },
    {
      'name': 'Dr. Lisa Ray',
      'specialty': 'Psychiatrist',
      'city': 'Seattle',
      'fee': 160.0,
      'experience': 11,
      'rating': 4.9,
      'bio': 'Compassionate mental health professional focusing on anxiety, depression, and cognitive behavioral therapy.',
      'photo': 'https://i.pravatar.cc/150?img=43',
      'slots': ['11:00 AM', '02:00 PM', '05:30 PM'],
      'qualifications': 'MBBS, MD (Psychiatry), DPM',
      'gender': 'Female',
      'availableToday': true,
      'bookedCount': 350,
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 5)),
      'reviews': [
        {
          'name': 'Daniel W.',
          'rating': 5,
          'comment': 'Extremely supportive sessions. I look forward to every consult.',
        },
      ],
    },
    {
      'name': 'Dr. James Patel',
      'specialty': 'Ophthalmologist',
      'city': 'Chicago',
      'fee': 110.0,
      'experience': 6,
      'rating': 4.5,
      'bio': 'Providing comprehensive eye exams, laser vision correction, and cataracts consultation.',
      'photo': 'https://i.pravatar.cc/150?img=15',
      'slots': ['09:00 AM', '10:00 AM', '01:30 PM'],
      'qualifications': 'MBBS, MS (Ophthalmology), FICO',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 210,
      'createdAt': Timestamp.fromDate(DateTime(2025, 4, 2)),
      'reviews': [],
    },
    {
      'name': 'Dr. Sophia Martinez',
      'specialty': 'Endocrinologist',
      'city': 'Miami',
      'fee': 145.0,
      'experience': 8,
      'rating': 4.7,
      'bio': 'Specialist in diabetes care, thyroid hormone imbalances, and metabolic wellness.',
      'photo': 'https://i.pravatar.cc/150?img=41',
      'slots': ['10:30 AM', '01:00 PM', '04:00 PM'],
      'qualifications': 'MBBS, MD (Endocrinology), CED',
      'gender': 'Female',
      'availableToday': false,
      'bookedCount': 275,
      'createdAt': Timestamp.fromDate(DateTime(2025, 3, 25)),
      'reviews': [
        {
          'name': 'Carlos G.',
          'rating': 5,
          'comment': 'My diabetes management has never been better. Highly recommended.',
        },
      ],
    },
    {
      'name': 'Dr. David Kim',
      'specialty': 'Dentist',
      'city': 'New York',
      'fee': 95.0,
      'experience': 5,
      'rating': 4.6,
      'bio': 'Expert in cosmetic dentistry, painless root canals, and pediatric dental hygiene.',
      'photo': 'https://i.pravatar.cc/150?img=33',
      'slots': ['08:00 AM', '11:00 AM', '03:00 PM'],
      'qualifications': 'BDS, MDS (Conservative Dentistry)',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 190,
      'createdAt': Timestamp.fromDate(DateTime(2025, 5, 10)),
      'reviews': [],
    },
    {
      'name': 'Dr. Fiona Gallagher',
      'specialty': 'General Physician',
      'city': 'Los Angeles',
      'fee': 80.0,
      'experience': 7,
      'rating': 4.4,
      'bio': 'Primary care practitioner specializing in preventative medicine and family health counseling.',
      'photo': 'https://i.pravatar.cc/150?img=45',
      'slots': ['09:00 AM', '12:30 PM', '03:00 PM', '06:00 PM'],
      'qualifications': 'MBBS, FCPS (Family Medicine)',
      'gender': 'Female',
      'availableToday': true,
      'bookedCount': 150,
      'createdAt': Timestamp.fromDate(DateTime(2025, 5, 28)),
      'reviews': [
        {
          'name': 'Ben Y.',
          'rating': 4,
          'comment': 'Straightforward and caring. Got my flu treatment in one session.',
        },
      ],
    },
    {
      'name': 'Dr. Arsalan Khan',
      'specialty': 'Cardiologist',
      'city': 'Houston',
      'fee': 180.0,
      'experience': 14,
      'rating': 4.9,
      'bio': 'Renowned interventionist cardiologist with expertise in heart disease prevention strategies.',
      'photo': 'https://i.pravatar.cc/150?img=3',
      'slots': ['11:00 AM', '02:00 PM', '04:00 PM'],
      'qualifications': 'MBBS, MD (Cardiology), FSCAI',
      'gender': 'Male',
      'availableToday': true,
      'bookedCount': 405,
      'createdAt': Timestamp.fromDate(DateTime(2025, 1, 19)),
      'reviews': [
        {
          'name': 'Rebecca D.',
          'rating': 5,
          'comment': 'Detailed diagnosis and a clear prevention plan. Excellent doctor.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> dummyMedicines = [
    {
      'name': 'Paracetamol 500mg',
      'brand': 'Panadol',
      'category': 'Antipyretics',
      'price': 4.99,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
      'requiresPrescription': false,
      'description': 'Fever and mild pain relief tablets.',
      'stock': 200,
    },
    {
      'name': 'Amoxicillin 250mg',
      'brand': 'Mox',
      'category': 'Antibiotics',
      'price': 9.49,
      'image': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=200',
      'requiresPrescription': true,
      'description': 'Broad-spectrum antibiotic capsules.',
      'stock': 120,
    },
    {
      'name': 'Panadol Extra',
      'brand': 'GSK',
      'category': 'Analgesics',
      'price': 6.79,
      'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=200',
      'requiresPrescription': false,
      'description': 'Paracetamol + caffeine for stronger pain relief.',
      'stock': 160,
    },
    {
      'name': 'Ibuprofen 400mg',
      'brand': 'Advil',
      'category': 'Analgesics',
      'price': 7.25,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
      'requiresPrescription': false,
      'description': 'Anti-inflammatory pain relief tablets.',
      'stock': 140,
    },
    {
      'name': 'Aspirin 100mg',
      'brand': 'Bayer',
      'category': 'Analgesics',
      'price': 5.49,
      'image': 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=200',
      'requiresPrescription': false,
      'description': 'Blood thinner and pain relief tablets.',
      'stock': 180,
    },
    {
      'name': 'Cetirizine 10mg',
      'brand': 'Zyrtec',
      'category': 'Cough & Cold',
      'price': 8.15,
      'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=200',
      'requiresPrescription': false,
      'description': 'Non-drowsy allergy and cold relief.',
      'stock': 150,
    },
    {
      'name': 'Vitamin C 1000mg',
      'brand': 'Centrum',
      'category': 'Vitamins',
      'price': 11.99,
      'image': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=200',
      'requiresPrescription': false,
      'description': 'Daily immune support effervescent tablets.',
      'stock': 220,
    },
    {
      'name': 'Vitamin D3 2000IU',
      'brand': 'Nature Made',
      'category': 'Vitamins',
      'price': 13.50,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
      'requiresPrescription': false,
      'description': 'Bone health and mood support softgels.',
      'stock': 190,
    },
    {
      'name': 'Antacid Suspension',
      'brand': 'Gaviscon',
      'category': 'Antacids',
      'price': 7.90,
      'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=200',
      'requiresPrescription': false,
      'description': 'Fast relief from heartburn and acidity.',
      'stock': 130,
    },
    {
      'name': 'Omeprazole 20mg',
      'brand': 'Prilosec',
      'category': 'Antacids',
      'price': 10.20,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
      'requiresPrescription': true,
      'description': 'Acid reflux and GERD treatment capsules.',
      'stock': 100,
    },
    {
      'name': 'Oral Rehydration Salts',
      'brand': 'Electral',
      'category': 'First Aid',
      'price': 3.40,
      'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=200',
      'requiresPrescription': false,
      'description': 'Electrolyte sachets for dehydration.',
      'stock': 300,
    },
    {
      'name': 'Thermometer',
      'brand': 'Omron',
      'category': 'First Aid',
      'price': 15.99,
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
      'requiresPrescription': false,
      'description': 'Digital clinical thermometer.',
      'stock': 80,
    },
  ];

  static Future<void> seedDoctors() async {
    final doctorsCollection = FirebaseFirestore.instance.collection('doctors');
    final existing = await doctorsCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      // print"Doctors already seeded! Skipping...");
      await upgradeDoctors();
      return;
    }
    // print"Seeding 12 premium doctors...");
    for (final doc in dummyDoctors) {
      await doctorsCollection.add(doc);
    }
    // print"Success! 12 doctors seeded.");
  }

  /// Back-fills the new filter fields on already-seeded doctor docs.
  static Future<void> upgradeDoctors() async {
    final doctorsCollection = FirebaseFirestore.instance.collection('doctors');
    final snapshot = await doctorsCollection.get();
    int updated = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('availableToday') &&
          data.containsKey('qualifications') &&
          data.containsKey('gender')) {
        continue;
      }
      final match = dummyDoctors.where((d) => d['name'] == data['name']).toList();
      if (match.isEmpty) continue;
      final merged = {...match.first, ...data};
      await doc.reference.set(merged);
      updated++;
    }
    // print"Upgraded $updated doctor docs with extended fields.");
  }

  static Future<void> seedMedicines() async {
    final medicinesCollection = FirebaseFirestore.instance.collection('medicines');
    final existing = await medicinesCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      // print"Medicines already seeded! Skipping...");
      return;
    }
    // print"Seeding medicines catalogue...");
    for (final doc in dummyMedicines) {
      await medicinesCollection.add(doc);
    }
    // print"Success! Medicines seeded.");
  }

  static Future<void> seedAll() async {
    // await seedDoctors();
    await seedMedicines();
  }
}