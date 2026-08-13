import 'package:flutter/material.dart';
import '../components/button.dart';
import '../layouts/responsive_layout.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/not-found',
      showFooter: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.iceBlue.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: 80,
                color: AppColors.mediumBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '404',
              style: AppTypography.displayLarge.copyWith(
                fontSize: 56,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page Not Found',
              style: AppTypography.titleLarge.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist\nor has been moved.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 28),
            SharedButton(
              label: 'Back to Home',
              icon: Icons.home_outlined,
              width: 220,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}