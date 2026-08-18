import 'package:flutter/material.dart';
import '../styles/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? AppColors.deepBlue,
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
        constraints: BoxConstraints.tightFor(width: size, height: size),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class DoctorCardSkeleton extends StatelessWidget {
  const DoctorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 80, height: 80, radius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 18),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 12),
                SizedBox(height: 12),
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 12),
                SkeletonBox(width: double.infinity, height: 36, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorGridSkeleton extends StatelessWidget {
  const DoctorGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.iceBlue, width: 1.5),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SkeletonBox(width: 90, height: 90, radius: 45)),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 16),
              SizedBox(height: 8),
              SkeletonBox(width: 90, height: 12),
              SizedBox(height: 12),
              SkeletonBox(width: 70, height: 12),
              SizedBox(height: 14),
              SkeletonBox(width: double.infinity, height: 40, radius: 8),
            ],
          ),
        );
      },
    );
  }
}