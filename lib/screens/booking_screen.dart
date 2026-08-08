import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../providers/appointments_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  String _selectedConsultationType = 'Video Call';

  final List<String> _consultationTypes = ['Video Call', 'In-App Chat', 'In-Person'];

  List<DateTime> _generateNextSevenDays() {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

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
          title: Text('Booking Error', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'No doctor data found. Please select a doctor again.',
            style: AppTypography.bodyLarge,
          ),
        ),
      );
    }

    final doctor = args;
    final dates = _generateNextSevenDays();

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final bookedSlotsAsync = ref.watch(bookedSlotsProvider('${doctor.name}_$dateStr'));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Book Appointment', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
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
                    Text('Select Date', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final date = dates[index];
                          final isSelected = date.day == _selectedDate.day &&
                              date.month == _selectedDate.month &&
                              date.year == _selectedDate.year;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                                _selectedTimeSlot = null;
                              });
                            },
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
                                    _getWeekdayName(date.weekday),
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
                    ),
                    const SizedBox(height: 28),
                    Text('Available Time Slots', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    bookedSlotsAsync.when(
                      data: (bookedSlots) {
                        final availableSlots = doctor.slots
                            .where((slot) => !bookedSlots.contains(slot))
                            .toList();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableSlots[index];
                            final isSelected = _selectedTimeSlot == slot;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTimeSlot = slot;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.deepBlue
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.deepBlue
                                        : AppColors.lightBlue.withValues(alpha: 0.5),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  slot,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.deepBlue,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.deepBlue),
                      ),
                      error: (err, stack) => const Center(
                        child: Text('Error loading slots'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Consultation Type', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: _consultationTypes.map((type) {
                        final isSelected = _selectedConsultationType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedConsultationType = type;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.deepBlue : AppColors.lightBlue.withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                type,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: isSelected ? AppColors.white : AppColors.deepBlue,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _selectedTimeSlot == null
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          '/payment',
                          arguments: {
                            'doctor': doctor,
                            'date': _selectedDate,
                            'slot': _selectedTimeSlot,
                            'type': _selectedConsultationType,
                          },
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  disabledBackgroundColor: AppColors.iceBlue,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Proceed to Payment',
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}