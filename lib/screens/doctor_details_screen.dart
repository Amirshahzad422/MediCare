import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class DoctorDetailsScreen extends StatelessWidget {
  const DoctorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        doctor.specialty,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumBlue, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Rating', '${doctor.rating} ⭐', AppColors.iceBlue),
                        _buildStatCard('Experience', '${doctor.experience} Yrs', AppColors.iceBlue),
                        _buildStatCard('Fee', '\$${doctor.fee.toStringAsFixed(0)}', AppColors.iceBlue),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Biography',
                      style: AppTypography.titleLarge.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.bio,
                      style: AppTypography.bodyLarge.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
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
                child: Text(
                  'Book Appointment',
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.lightBlue),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
