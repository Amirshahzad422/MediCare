import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/search_bar.dart';
import '../components/category_chip.dart';
import '../components/doctor_card.dart';
import '../components/testimonials.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  final _scrollController = ScrollController();
  final _resultsKey = GlobalKey();
  Timer? _bannerTimer;
  int _bannerIndex = 0;
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

  static const List<({String title, String subtitle, IconData icon, Color color})> _banners = [
    (
      title: 'Consult Specialists Online',
      subtitle: 'Video consults with certified doctors — within minutes.',
      icon: Icons.video_call_outlined,
      color: AppColors.deepBlue,
    ),
    (
      title: 'Digital Prescriptions',
      subtitle: 'Get your e-prescription right after the consultation.',
      icon: Icons.description_outlined,
      color: AppColors.mediumBlue,
    ),
    (
      title: 'Medicines at Your Door',
      subtitle: 'Order from your prescription and track every delivery.',
      icon: Icons.local_shipping_outlined,
      color: AppColors.darkNavy,
    ),
  ];

  static const List<(String, String, String)> _whyUs = [
    ('Verified Doctors', 'Every specialist is certified and reviewed by real patients.', 'verified_user'),
    ('24/7 Access', 'Book and consult any time, from any device.', 'access_time'),
    ('Secure & Private', 'Your records are encrypted and only yours to share.', 'lock_outline'),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.iceBlue,
                      backgroundImage: profile.value?.photo != null && profile.value!.photo.isNotEmpty
                          ? NetworkImage(profile.value!.photo)
                          : null,
                      child: profile.value?.photo == null || profile.value!.photo.isEmpty
                          ? const Icon(Icons.person, color: AppColors.deepBlue)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            showSearchIcon: false,
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.deepBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: AppColors.white),
                            onPressed: () {
                              if (_searchController.text.isNotEmpty && _resultsKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  _resultsKey.currentContext!,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _bannerCarousel(),
                  const SizedBox(height: 24),
                  _whyChooseUs(),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore by Specialty',
                          style: AppTypography.titleLarge.copyWith(fontSize: 20),
                        ),
                        _seeAllButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 20),
                  Padding(
                    key: _resultsKey,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Doctors',
                          style: AppTypography.titleLarge.copyWith(fontSize: 20),
                        ),
                       
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  doctorsAsync.when(
                    data: (doctors) {
                      final filteredDoctors = doctors.where((doc) {
                        final matchesCategory = _selectedCategory == 'All' ||
                            doc.specialty.toLowerCase() == _selectedCategory.toLowerCase();
                        final matchesSearch =
                            doc.name.toLowerCase().contains(_searchQuery) ||
                                doc.specialty.toLowerCase().contains(_searchQuery);
                        return matchesCategory && matchesSearch;
                      }).toList();

                      if (filteredDoctors.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No doctors found',
                              style: AppTypography.bodyLarge,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              children: List.generate(
                                filteredDoctors.length.clamp(0, 5),
                                (index) {
                                  final doctor = filteredDoctors[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: DoctorCard(
                                      doctor: doctor,
                                      onBookTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/doctor-details',
                                          arguments: doctor,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (filteredDoctors.length > 5)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/doctors'),
                                child: Text(
                                  'View all ${filteredDoctors.length} doctors →',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.deepBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.deepBlue,
                        ),
                      ),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Failed to load doctors',
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'What Our Patients Say',
                      style: AppTypography.titleLarge.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TestimonialsCarousel(
                    height: 230,
                    testimonials: [
                      TestimonialCard(
                        name: 'Hannah L.',
                        role: 'Patient',
                        rating: 5,
                        message: 'Booked a dermatologist in minutes and had my video consult the '
                            'same afternoon. The e-prescription was ready instantly.',
                      ),
                      TestimonialCard(
                        name: 'Marcus T.',
                        role: 'Patient',
                        rating: 5,
                        message: 'Being able to order my medicines straight from the prescription '
                            'saved me a whole pharmacy trip.',
                      ),
                      TestimonialCard(
                        name: 'Priya N.',
                        role: 'Patient',
                        rating: 4,
                        message: 'The doctor filters are fantastic - I found a pediatrician '
                            'available today without any phone calls.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _ctaBanner(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerCarousel() {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [banner.color, AppColors.mediumBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: banner.color.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner.title,
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 20,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner.subtitle,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.iceBlue,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(banner.icon, size: 32, color: AppColors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _bannerIndex ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index == _bannerIndex
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyChooseUs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose MediCare?',
            style: AppTypography.titleLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (index) {
                if (index.isOdd) return const SizedBox(width: 10);
                
                final itemIndex = index ~/ 2;
                final item = _whyUs[itemIndex];
                
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.iceBlue, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.iceBlue.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _whyUsIcon(item.$3),
                            color: AppColors.deepBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.$1,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  IconData _whyUsIcon(String name) {
    switch (name) {
      case 'verified_user':
        return Icons.verified_user_outlined;
      case 'access_time':
        return Icons.access_time_outlined;
      default:
        return Icons.lock_outline;
    }
  }

  Widget _seeAllButton() {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/doctors'),
      child: Text(
        'See All',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _ctaBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.deepBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Not feeling well? A doctor is minutes away.',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(fontSize: 18, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/doctors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iceBlue,
              foregroundColor: AppColors.deepBlue,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.local_hospital_outlined),
            label: const Text('Book a Consultation'),
          ),
        ],
      ),
    );
  }
}