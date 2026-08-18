import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class DatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final List<DateTime>? dates;

  const DatePickerRow({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    this.dates,
  });

  List<DateTime> get _dates =>
      dates ?? List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  String get _weekdayName {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[selectedDate.weekday];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          return GestureDetector(
            onTap: () => onSelect(date),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.deepBlue : AppColors.lightBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.white : AppColors.lightBlue,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      color: isSelected ? AppColors.white : AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SlotGrid extends StatelessWidget {
  final List<String> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSelect;

  const SlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlot == slot;
        return GestureDetector(
          onTap: () => onSelect(slot),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.deepBlue : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.deepBlue : AppColors.lightBlue.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              slot,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.deepBlue,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
