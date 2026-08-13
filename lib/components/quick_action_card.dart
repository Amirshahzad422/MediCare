import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.iceBlue, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkNavy.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max, // Helps with stretching
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.iceBlue.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.deepBlue, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}