import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class MedicineCard extends ConsumerWidget {
  final MedicineModel medicine;
  final bool horizontal;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = horizontal
        ? Row(
            children: [
              _medicineImage(size: 72),
              const SizedBox(width: 12),
              Expanded(child: _infoColumn(context)),
              const SizedBox(width: 8),
              Text(
                '\$${medicine.price.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 16,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _medicineImage(size: 84)),
              const SizedBox(height: 10),
              Expanded(child: _infoColumn(context)),
              const SizedBox(height: 8),
              Text(
                '\$${medicine.price.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 16,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/medicine-detail',
          arguments: medicine,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FCFF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(
            color: AppColors.mediumBlue.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlue.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _medicineImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: AppColors.lightBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: medicine.image.isNotEmpty && medicine.image.startsWith('http')
            ? Image.network(
                medicine.image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.iceBlue,
                  child: Icon(Icons.medication, color: AppColors.deepBlue, size: size * 0.45),
                ),
              )
            : Container(
                color: AppColors.iceBlue,
                child: Icon(Icons.medication, color: AppColors.deepBlue, size: size * 0.45),
              ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.iceBlue.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            medicine.category,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 9,
              color: AppColors.deepBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          medicine.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleLarge.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          medicine.brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
