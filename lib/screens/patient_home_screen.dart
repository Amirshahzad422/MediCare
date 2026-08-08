import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/search_bar.dart';
import '../components/category_chip.dart';
import '../components/doctor_card.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Dentist',
    'Psychiatrist',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final doctorsAsync = ref.watch(doctorsListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        profile.value?.name ?? 'Patient',
                        style: AppTypography.titleLarge,
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.iceBlue,
                    child: Icon(
                      Icons.person,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return CategoryChip(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Featured Doctors',
                style: AppTypography.titleLarge.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: doctorsAsync.when(
                data: (doctors) {
                  final filteredDoctors = doctors.where((doc) {
                    final matchesCategory = _selectedCategory == 'All' ||
                        doc.specialty.toLowerCase() == _selectedCategory.toLowerCase();
                    final matchesSearch = doc.name.toLowerCase().contains(_searchQuery) ||
                        doc.specialty.toLowerCase().contains(_searchQuery);
                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filteredDoctors.isEmpty) {
                    return Center(
                      child: Text(
                        'No doctors found',
                        style: AppTypography.bodyLarge,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    itemCount: filteredDoctors.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doctor = filteredDoctors[index];
                      return DoctorCard(
                        doctor: doctor,
                        onBookTap: () {
                          Navigator.pushNamed(
                            context,
                            '/doctor-details',
                            arguments: doctor,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.deepBlue,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Failed to load doctors',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}