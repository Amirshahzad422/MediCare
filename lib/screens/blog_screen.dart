import 'package:flutter/material.dart';
import '../layouts/responsive_layout.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  static const List<({String title, String category, String date, String excerpt})> _posts = [
    (
      title: '5 Signs You Should See a Cardiologist Early',
      category: 'Heart Health',
      date: 'July 28, 2026',
      excerpt: 'Shortness of breath, chest discomfort and fatigue can be early signals. '
          'Here is when to book a consult instead of waiting.',
    ),
    (
      title: 'Telemedicine Is Changing Rural Healthcare',
      category: 'Telemedicine',
      date: 'July 15, 2026',
      excerpt: 'How video consultations are closing the specialist gap for patients '
          'hours away from the nearest clinic.',
    ),
    (
      title: 'Understanding Your Digital Prescription',
      category: 'Prescriptions',
      date: 'June 30, 2026',
      excerpt: 'Dosage, frequency, duration — a plain-English guide to reading '
          'the medicine orders you receive after a consult.',
    ),
    (
      title: '7 Habits for a Healthier Immune System',
      category: 'Wellness',
      date: 'June 12, 2026',
      excerpt: 'Sleep, hydration, movement and stress management — practical habits '
          'your general physician would recommend.',
    ),
    (
      title: 'What to Ask in Your First Video Consultation',
      category: 'Consultations',
      date: 'May 25, 2026',
      excerpt: 'Prepare like a pro: symptoms timeline, medications list and the '
          'questions that get you the most value from your doctor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/blog',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health & Wellness Blog', style: AppTypography.displayLarge.copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'Practical health insights written by the doctors on MediCare.',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.lightBlue),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) => _BlogCard(post: _posts[index]),
                      );
                    }
                    return Column(
                      children: _posts.map((post) => _BlogCard(post: post)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final ({String title, String category, String date, String excerpt}) post;

  const _BlogCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.category,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 10,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(post.date, style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              post.excerpt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkNavy,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read Article →',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.deepBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}