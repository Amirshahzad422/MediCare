import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/doctor_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'loader.dart';

class ScheduleView extends ConsumerStatefulWidget {
  final String doctorName;
  final Future<void> Function(bool available) onAvailabilityChanged;

  const ScheduleView({
    super.key,
    required this.doctorName,
    required this.onAvailabilityChanged,
  });

  @override
  ConsumerState<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<ScheduleView> {
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _durations = ['15', '30', '45', '60'];

  late List<String> _selectedDays;
  late int _startHour;
  late int _endHour;
  late int _duration;
  bool _hasChanges = false;
  bool _initialized = false;

  String _formatTime(TimeOfDay time) {
    final hr = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hr:$min $period';
  }

  List<String> _generateSlots(int duration, int startHour, int endHour) {
    final slots = <String>[];
    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60;

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += duration) {
        final slotStart = hour * 60 + minute;
        final slotEnd = slotStart + duration;
        if (slotStart >= startMinutes && slotEnd <= endMinutes) {
          final period = hour < 12 ? 'AM' : 'PM';
          int displayHour = hour % 12;
          if (displayHour == 0) displayHour = 12;
          final displayMinute = minute.toString().padLeft(2, '0');
          slots.add('$displayHour:$displayMinute $period');
        }
      }
    }
    return slots;
  }

  Future<void> _pickTime(String label, int currentHour, ValueChanged<TimeOfDay> onSelected) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.deepBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort((a, b) => _allDays.indexOf(a).compareTo(_allDays.indexOf(b)));
      _hasChanges = true;
    });
  }

  void _toggleTodayAvailability(bool enable) {
    final todayName = _allDays[DateTime.now().weekday - 1];
    setState(() {
      if (enable) {
        if (!_selectedDays.contains(todayName)) {
          _selectedDays.add(todayName);
          _selectedDays.sort((a, b) => _allDays.indexOf(a).compareTo(_allDays.indexOf(b)));
        }
      } else {
        _selectedDays.remove(todayName);
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_endHour <= _startHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final todayName = _allDays[DateTime.now().weekday - 1];
    final availableToday = _selectedDays.contains(todayName);
    final generatedSlots = _generateSlots(_duration, _startHour, _endHour);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updateData = {
      'availableDays': _selectedDays,
      'businessStartHour': _startHour,
      'businessEndHour': _endHour,
      'consultationDuration': _duration,
      'slots': generatedSlots,
      'availableToday': availableToday,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));

    final docsSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .where('name', isEqualTo: widget.doctorName)
        .get();
    for (var doc in docsSnap.docs) {
      await doc.reference.update(updateData);
    }

    ref.invalidate(doctorsListProvider);
    ref.invalidate(userDocProvider);

    setState(() => _hasChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocProvider);

    return userDoc.when(
      data: (doc) {
        if (!_initialized && doc != null) {
          _selectedDays = (doc['availableDays'] as List?)?.cast<String>() ?? [];
          _startHour = doc['businessStartHour'] ?? 8;
          _endHour = doc['businessEndHour'] ?? 18;
          _duration = doc['consultationDuration'] ?? 30;
          _initialized = true;
        }

        final todayName = _allDays[DateTime.now().weekday - 1];
        final isAvailableToday = _selectedDays.contains(todayName);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Today (interactive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.iceBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Today',
                      style: AppTypography.titleLarge.copyWith(fontSize: 16),
                    ),
                    Switch(
                      value: isAvailableToday,
                      onChanged: _toggleTodayAvailability,
                      activeThumbColor: AppColors.deepBlue,
                      inactiveThumbColor: AppColors.mediumBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Available Days
              Text('Available Days', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Select the days you work.', style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.deepBlue,
                    backgroundColor: AppColors.iceBlue.withOpacity(0.3),
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.white : AppColors.deepBlue,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.deepBlue : AppColors.lightBlue,
                        width: 1,
                      ),
                    ),
                    onSelected: (_) => _toggleDay(day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Business Hours
              Text('Business Hours', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Set your working hours.', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime('Start', _startHour, (time) {
                        setState(() {
                          _startHour = time.hour;
                          _hasChanges = true;
                        });
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightBlue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('From', style: AppTypography.bodyMedium),
                            Text(
                              _formatTime(TimeOfDay(hour: _startHour, minute: 0)),
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime('End', _endHour, (time) {
                        setState(() {
                          _endHour = time.hour;
                          _hasChanges = true;
                        });
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightBlue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('To', style: AppTypography.bodyMedium),
                            Text(
                              _formatTime(TimeOfDay(hour: _endHour, minute: 0)),
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Consultation Duration
              Text('Consultation Duration', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('How long does each session last?', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightBlue),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<int>(
                  value: _duration,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _durations.map((e) {
                    final value = int.parse(e);
                    return DropdownMenuItem(
                      value: value,
                      child: Text('$e Minutes', style: AppTypography.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        _duration = newVal;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanges ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    disabledBackgroundColor: AppColors.iceBlue,
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.mediumBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppTypography.buttonText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(size: 24),
      error: (err, stack) => const SizedBox(),
    );
  }
}