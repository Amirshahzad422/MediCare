import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final bool showSearchIcon;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.showSearchIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search doctors or specialties...',
          hintStyle: AppTypography.bodyMedium,
          prefixIcon: showSearchIcon ? const Icon(Icons.search, color: AppColors.mediumBlue) : null,
          suffixIcon: onFilterTap != null
              ? IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.deepBlue),
                  onPressed: onFilterTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}