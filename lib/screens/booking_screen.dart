import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../providers/appointments_provider.dart';
import '../components/slot_picker.dart' hide formatDateKey;
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'package:intl/intl.dart';

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

  List<String> _generateSlotsFallback(DoctorModel doctor) {
    final List<String> slots = [];
    final duration = doctor.consultationDuration;
    final startHour = doctor.businessStartHour;
    final endHour = doctor.businessEndHour;
    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60;

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += duration) {
        final slotStart = hour * 60 + minute;
        final slotEnd = slotStart + duration;
        if (slotStart >= startMinutes && slotEnd <= endMinutes) {
          final time = DateTime(2024, 1, 1, hour, minute);
          slots.add(DateFormat('hh:mm a').format(time));
        }
      }
    }
    return slots;
  }

  List<String> _getSlotsForDate(DoctorModel doctor, DateTime date) {
    List<String> allSlots = doctor.slots.isNotEmpty ? doctor.slots : _generateSlotsFallback(doctor);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final currentTime = TimeOfDay.fromDateTime(now);
      allSlots = allSlots.where((slot) {
        final slotTime = DateFormat('hh:mm a').parse(slot);
        final slotHour = slotTime.hour;
        final slotMinute = slotTime.minute;
        if (slotHour > currentTime.hour) return true;
        if (slotHour == currentTime.hour && slotMinute > currentTime.minute) return true;
        return false;
      }).toList();
    }
    return allSlots;
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

    final String dayName = DateFormat('EEEE').format(_selectedDate);
    final bool isAvailableDay = doctor.availableDays.contains(dayName);
    final dateStr = formatDateKey(_selectedDate);
    final bookedSlotsAsync = ref.watch(bookedSlotsProvider('${doctor.id}_$dateStr'));

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
                    _doctorBrief(doctor),
                    const SizedBox(height: 24),
                    Text('Select Date', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Time Slots',
                          style: AppTypography.titleLarge.copyWith(fontSize: 18),
                        ),
                        Text(
                          '${doctor.consultationDuration} min',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.mediumBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Business hours: ${_formatHour(doctor.businessStartHour)} - ${_formatHour(doctor.businessEndHour)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.mediumBlue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isAvailableDay)
                      _unavailableState('Doctor is not available on $dayName')
                    else
                      bookedSlotsAsync.when(
                        data: (bookedSlots) {
                          final allSlots = _getSlotsForDate(doctor, _selectedDate);
                          final availableSlots = allSlots
                              .where((slot) => !bookedSlots.contains(slot))
                              .toList();

                          if (availableSlots.isEmpty) {
                            return _unavailableState('No slots available for this day.');
                          }

                          return SlotGrid(
                            slots: availableSlots,
                            selectedSlot: _selectedTimeSlot,
                            onSelect: (slot) {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
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
                    _typeSelector(),
                  ],
                ),
              ),
            ),
            _bottomBar(doctor),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
      ),
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
            _selectedTimeSlot = null;
          });
        },
      ),
    );
  }

  String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display $suffix';
  }

  Widget _doctorBrief(DoctorModel doctor) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: doctor.photo.isNotEmpty && doctor.photo.startsWith('http')
              ? Image.network(
                  doctor.photo,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.iceBlue,
                    child: const Icon(Icons.person, color: AppColors.deepBlue),
                  ),
                )
              : Container(
                  width: 52,
                  height: 52,
                  color: AppColors.iceBlue,
                  child: const Icon(Icons.person, color: AppColors.deepBlue),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(fontSize: 16),
              ),
              Text(
                doctor.specialty,
                style: AppTypography.bodyMedium.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          '\$${doctor.fee.toStringAsFixed(0)}',
          style: AppTypography.titleLarge.copyWith(
            fontSize: 16,
            color: AppColors.deepBlue,
          ),
        ),
      ],
    );
  }

  Widget _unavailableState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.iceBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.mediumBlue),
      ),
    );
  }

  Widget _typeSelector() {
    return Row(
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
                color: isSelected
                    ? AppColors.deepBlue
                    : AppColors.iceBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.deepBlue
                      : AppColors.lightBlue.withOpacity(0.2),
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
    );
  }

  Widget _bottomBar(DoctorModel doctor) {
    return Padding(
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
          'Proceed to Payment'.toUpperCase(),
          style: AppTypography.buttonText,
        ),
      ),
    );
  }
}