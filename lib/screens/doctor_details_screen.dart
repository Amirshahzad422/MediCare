import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../providers/doctor_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class DoctorDetailsScreen extends ConsumerWidget {
  const DoctorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! DoctorModel) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkNavy),
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          title: Text('Profile Error', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'No doctor selection found. Please go back.',
            style: AppTypography.bodyLarge,
          ),
        ),
      );
    }

    final doctor = args;
    final doctorsAsync = ref.watch(doctorsListProvider);
    final favouritesAsync = ref.watch(favouritesProvider);
    final isFavourite =
        favouritesAsync.value?.contains(doctor.id) ?? false;

    final similarDoctors = doctorsAsync.value
            ?.where((d) => d.id != doctor.id && d.specialty == doctor.specialty)
            .take(3)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Doctor Profile', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: () async {
              final ok = await ref
                  .read(profileServiceProvider)
                  .toggleFavourite(doctor.id);
              if (ok) {
                ref.invalidate(favouritesProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavourite
                        ? 'Removed from favourites'
                        : 'Added to favourites'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        isFavourite ? AppColors.grey : AppColors.deepBlue,
                  ),
                );
              }
            },
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: isFavourite ? AppColors.error : AppColors.lightBlue,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(doctor),
                    const SizedBox(height: 24),
                    _stats(doctor),
                    const SizedBox(height: 24),
                    if (doctor.qualifications.isNotEmpty) ...[
                      Text(
                        'Qualifications',
                        style: AppTypography.titleLarge.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.iceBlue.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_outlined, color: AppColors.deepBlue, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                doctor.qualifications,
                                style: AppTypography.bodyLarge.copyWith(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Biography',
                      style: AppTypography.titleLarge.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.bio,
                      style: AppTypography.bodyLarge.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (doctor.reviews.isNotEmpty) ...[
                      Text(
                        'Patient Reviews',
                        style: AppTypography.titleLarge.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      ...doctor.reviews.map((review) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.iceBlue, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review['name'] ?? 'Patient',
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                            i < ((review['rating'] ?? 5) as num).toInt()
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 15,
                                          )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  review['comment'] ?? '',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.darkNavy,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (similarDoctors.isNotEmpty) ...[
                      Text(
                        'Similar Doctors',
                        style: AppTypography.titleLarge.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      ...similarDoctors.map((similar) => GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              '/doctor-details',
                              arguments: similar,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.iceBlue, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      similar.photo,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 44,
                                        height: 44,
                                        color: AppColors.iceBlue,
                                        child: const Icon(Icons.person,
                                            color: AppColors.deepBlue, size: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          similar.name,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTypography.titleLarge.copyWith(fontSize: 14),
                                        ),
                                        Text(
                                          '${similar.experience} yrs • \$${similar.fee.toStringAsFixed(0)}',
                                          style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.lightBlue),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/booking',
                    arguments: doctor,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.event_available, color: AppColors.white),
                label: Text(
                  'Book Appointment'.toUpperCase(),
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DoctorModel doctor) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.iceBlue, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkNavy.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                doctor.photo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.iceBlue,
                    child: const Icon(Icons.person, size: 60, color: AppColors.deepBlue),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            doctor.name,
            style: AppTypography.displayLarge.copyWith(fontSize: 24),
          ),
        ),
        Center(
          child: Text(
            '${doctor.specialty} • ${doctor.city}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumBlue, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        if (doctor.availableToday)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available Today',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _stats(DoctorModel doctor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Rating', '${doctor.rating} ⭐', AppColors.iceBlue),
        _buildStatCard('Experience', '${doctor.experience} Yrs', AppColors.iceBlue),
        _buildStatCard('Fee', '\$${doctor.fee.toStringAsFixed(0)}', AppColors.iceBlue),
        _buildStatCard('Booked', '${doctor.bookedCount}+', AppColors.iceBlue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.lightBlue),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}