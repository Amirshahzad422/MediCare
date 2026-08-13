import 'package:flutter/material.dart';
import '../components/testimonials.dart';
import '../layouts/responsive_layout.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/about',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About MediCare', style: AppTypography.displayLarge.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                Text(
                  'Healthcare that fits in your pocket — certified doctors, instant consultations, '
                  'digital prescriptions and doorstep medicine delivery.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.lightBlue, height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _statCard('50K+', 'Patients Served'),
                    _statCard('500+', 'Certified Doctors'),
                    _statCard('4.8★', 'Average Rating'),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Our Mission', style: AppTypography.titleLarge.copyWith(fontSize: 22)),
                const SizedBox(height: 10),
                Text(
                  'To make quality healthcare accessible to everyone, everywhere. We connect patients '
                  'with the right specialist in seconds, replace phone-book scheduling with smart slot '
                  'booking, and bring consultations, prescriptions and medicine orders into one '
                  'seamless journey.',
                  style: AppTypography.bodyLarge.copyWith(height: 1.6),
                ),
                const SizedBox(height: 28),
                Text('What Patients Say', style: AppTypography.titleLarge.copyWith(fontSize: 22)),
                const SizedBox(height: 14),
                const TestimonialsCarousel(
                  height: 230,
                  testimonials: [
                    TestimonialCard(
                      name: 'Sarah M.',
                      role: 'Patient',
                      rating: 5,
                      message: 'Booked a cardiologist in under a minute and consulted over video '
                          'the same day. The digital prescription was a lifesaver!',
                    ),
                    TestimonialCard(
                      name: 'James K.',
                      role: 'Patient',
                      rating: 5,
                      message: 'Ordering medicines straight from my prescription and tracking the '
                          'delivery was effortless. Highly recommended.',
                    ),
                    TestimonialCard(
                      name: 'Ayesha R.',
                      role: 'Patient',
                      rating: 4,
                      message: 'The doctor search and filters helped me find exactly the right '
                          'specialist for my daughter. Amazing experience.',
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ready to meet your doctor?',
                        style: AppTypography.titleLarge.copyWith(fontSize: 20, color: AppColors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/doctors'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iceBlue,
                          foregroundColor: AppColors.deepBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.local_hospital_outlined),
                        label: const Text('Find a Doctor'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.iceBlue, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(fontSize: 22, color: AppColors.deepBlue),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}