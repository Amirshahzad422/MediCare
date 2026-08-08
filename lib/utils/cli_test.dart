import 'package:firedart/firedart.dart';

void main() async {
  // 1. Apne Firebase Project ID ke sath Firestore initialize karein
  const String projectId = 'medicare-cc907';
  Firestore.initialize(projectId);

  print('Live Firestore Database se connect ho rahe hain...');
  final CollectionReference doctorsCollection = Firestore.instance.collection('doctors');

  try {
    // 2. Pehle check karein ke kya database mein pehle se doctors hain?
    final List<Document> existingDocs = await doctorsCollection.get();

    if (existingDocs.isNotEmpty) {
      print('Database pehle se seeded hai! Total ${existingDocs.length} doctors found.');
      print('Skipping seeding to prevent duplicates.\n');
    } else {
      print('Database khali hai! 12 Premium Doctors seed kar rahe hain...');

      // Medicare requirements ke mutabiq 12 detailed doctors ka data [cite: 225]
      final List<Map<String, dynamic>> dummyDoctors = [
        {
          'name': 'Dr. Anna Grace',
          'specialty': 'Cardiologist',
          'city': 'New York',
          'fee': 150.0,
          'experience': 10,
          'rating': 4.9,
          'bio': 'Board-certified cardiologist with 10+ years of experience in heart care and cardiovascular research.',
          'photo': 'https://i.pravatar.cc/150?img=47',
          'slots': ['09:00 AM', '10:30 AM', '02:00 PM', '04:30 PM']
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
          'slots': ['10:00 AM', '11:00 AM', '01:00 PM', '03:00 PM']
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
          'slots': ['08:30 AM', '11:30 AM', '02:30 PM', '05:00 PM']
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
          'slots': ['09:00 AM', '11:00 AM', '03:00 PM']
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
          'slots': ['09:30 AM', '12:00 PM', '04:00 PM']
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
          'slots': ['10:00 AM', '01:00 PM', '03:30 PM']
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
          'slots': ['11:00 AM', '02:00 PM', '05:30 PM']
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
          'slots': ['09:00 AM', '10:00 AM', '01:30 PM']
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
          'slots': ['10:30 AM', '01:00 PM', '04:00 PM']
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
          'slots': ['08:00 AM', '11:00 AM', '03:00 PM']
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
          'slots': ['09:00 AM', '12:30 PM', '03:00 PM', '06:00 PM']
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
          'slots': ['11:00 AM', '02:00 PM', '04:00 PM']
        }
      ];

      // Loop chala kar Firestore mein upload karein
      for (var doc in dummyDoctors) {
        await doctorsCollection.add(doc);
        print('Added: ${doc['name']} (${doc['specialty']})');
      }
      print('\nSuccess! Seeding completed.');
    }

    // 3. Data verify karne ke liye dobara fetch karke list show karein
    print('Verifying database contents:');
    final List<Document> doctors = await doctorsCollection.get();
    print('-----------------------------------------');
    for (var doc in doctors) {
      final data = doc.map;
      print('Name:       ${data['name']}');
      print('Specialty:  ${data['specialty']}');
      print('City:       ${data['city']}');
      print('Fee:        \$${data['fee']}');
      print('Rating:     ${data['rating']}');
      print('-----------------------------------------');
    }

  } catch (e) {
    print('Connection or Seeding Error: $e');
  }
}