import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

/// Reusable testimonial card used across the Home & supporting screens.
class TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String message;
  final double rating;
  final String? photo;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.role,
    required this.message,
    required this.rating,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.iceBlue,
                backgroundImage: photo != null && photo!.isNotEmpty
                    ? NetworkImage(photo!)
                    : null,
                child: photo == null || photo!.isEmpty
                    ? const Icon(Icons.person, color: AppColors.deepBlue)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                    ),
                    Text(
                      role,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.format_quote, color: AppColors.lightBlue, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.darkNavy,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal carousel of testimonials with normalized scroll bar.
class TestimonialsCarousel extends StatelessWidget {
  final List<TestimonialCard> testimonials;
  final double height;

  const TestimonialsCarousel({
    super.key,
    required this.testimonials,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: testimonials.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => testimonials[index],
      ),
    );
  }
}