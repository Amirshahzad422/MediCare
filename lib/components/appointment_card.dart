import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/appointments_provider.dart';
import '../providers/doctor_provider.dart';
import '../models/doctor_model.dart';
import '../services/call_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

import '../providers/profile_provider.dart';
import 'prescription_writer_sheet.dart';

class AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> app;
  final int status;
  final Color statusColor;
  final Color statusBg;
  final bool isDoctor;

  const AppointmentCard({
    super.key,
    required this.app,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.isDoctor,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool _joiningCall = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final dateStr = app['date'] ?? '';
    final slotStr = app['slot'] ?? '';
    final type = app['type'] ?? 'Video';

    final doctorId = app['doctorId'] as String? ?? '';
    final patientId = app['patientId'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final String name;
              final String subtitle;
              final String photo;

              if (widget.isDoctor) {
                final patient = ref.watch(patientByIdProvider(patientId)).value;
                name = patient?['name'] ?? app['patientName'] ?? 'Patient';
                photo = patient?['photo'] ?? '';
                final age = patient?['age']?.toString() ?? '--';
                final gender = patient?['gender'] ?? '--';
                subtitle = 'Age: $age • Gender: $gender';
              } else {
                final doctor = ref.watch(doctorByIdProvider(doctorId)).value;
                name = doctor?.name ?? app['doctorName'] ?? 'Doctor';
                photo = doctor?.photo ?? app['doctorPhoto'] ?? '';
                final specialty = doctor?.specialty ?? app['specialty'] ?? 'Consultation';
                subtitle = specialty;
              }

              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: photo.isNotEmpty && photo.startsWith('http')
                        ? Image.network(
                            photo,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, _) => Container(
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
                          name,
                          style: AppTypography.titleLarge.copyWith(fontSize: 16),
                        ),
                        Text(subtitle, style: AppTypography.bodyMedium),
                        Text(
                          type,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.mediumBlue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status == 1 ? 'UPCOMING' : (widget.status == 2 ? 'PAST' : (widget.status == 3 ? 'CANCELLED' : 'UNKNOWN')),
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 10,
                        color: widget.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: AppColors.mediumBlue),
              const SizedBox(width: 6),
              Text(dateStr,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: AppColors.mediumBlue),
              const SizedBox(width: 6),
              Text(slotStr,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (widget.status == 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _joiningCall ? null : () => _joinCall(context, app),
                    icon: _joiningCall
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.video_call, size: 18),
                    label: Text(
                      _joiningCall ? 'Joining…' : 'Join Call',
                      style: AppTypography.buttonText.copyWith(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBlue,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Reschedule',
                  child: OutlinedButton(
                    onPressed: () => _reschedule(context, app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepBlue,
                      side: const BorderSide(color: AppColors.lightBlue),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.edit_calendar_outlined, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Cancel',
                  child: OutlinedButton(
                    onPressed: () => _cancel(context, app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.cancel_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ],
          if (widget.status == 2) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text('Consultation Completed',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.green)),
              ],
            ),
            if (widget.isDoctor) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openPrescriptionWriter(context),
                icon: const Icon(Icons.edit_document, size: 18),
                label: Text(
                  'Write Prescription',
                  style: AppTypography.buttonText.copyWith(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _openPrescriptionWriter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final docAsync = ref.watch(userDocProvider);
          final rawName = docAsync.value?['name'] ?? 'Doctor';
          final doctorName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';
          final specialty = docAsync.value?['specialty'] ?? 'General Physician';
          final photo = docAsync.value?['photo'] ?? '';

          return PrescriptionWriterSheet(
            doctorName: doctorName,
            specialty: specialty,
            doctorPhoto: photo,
            prefilledPatientId: widget.app['patientId'],
            prefilledPatientName: widget.app['patientName'],
          );
        },
      ),
    );
  }

  Future<void> _joinCall(BuildContext context, Map<String, dynamic> app) async {
    setState(() => _joiningCall = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final amIPatient = app['patientId'] == user?.uid;
      final callId = await CallService().ensureCallRoom(app);
      if (!context.mounted) return;
      Navigator.pushNamed(
        context,
        '/video-call',
        arguments: {
          ...app,
          'callId': callId,
          'isDoctor': !amIPatient,
        },
      );
    } finally {
      if (mounted) setState(() => _joiningCall = false);
    }
  }

  Future<void> _reschedule(BuildContext context, Map<String, dynamic> app) async {
    String? doctorId = app['doctorId'] as String?;
    if (doctorId == null || doctorId.isEmpty) {
      final doctorName = app['doctorName'] as String?;
      if (doctorName != null) {
        try {
          final snapshot = await FirebaseFirestore.instance.collection('doctors').where('name', isEqualTo: doctorName).limit(1).get();
          if (snapshot.docs.isNotEmpty) {
            doctorId = snapshot.docs.first.id;
          }
        } catch (_) {}
      }
    }

    if (doctorId == null || doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor ID not found. Please cancel and re-book.')),
      );
      return;
    }

    final container = ProviderScope.containerOf(context);

    final doctor = await container.read(doctorByIdProvider(doctorId).future);
    if (!mounted) return;

    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor not found.')),
      );
      return;
    }

    await _showRescheduleDialog(context, app, doctor, container);
  }

  Future<void> _showRescheduleDialog(
      BuildContext context,
      Map<String, dynamic> app,
      DoctorModel doctor,
      ProviderContainer container,
      ) async {
    DateTime originalDate = DateTime.now();
    try {
      originalDate = DateFormat('yyyy-MM-dd').parse(app['date'] ?? '');
    } catch (_) {}
    final firstAllowedDate = originalDate.isBefore(DateTime.now()) ? DateTime.now() : originalDate;

    DateTime selectedDate = firstAllowedDate;
    String selectedSlot = '';

    String formatDateKey(DateTime date) {
      return DateFormat('yyyy-MM-dd').format(date);
    }



    List<String> getSlotsForDate(DateTime date) {
      List<String> allSlots = doctor.slots.isNotEmpty
          ? doctor.slots
          : _generateFallbackSlots(doctor);
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



    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            final dateStr = formatDateKey(selectedDate);
            return Consumer(
              builder: (context, ref, child) {
                final bookedSlotsAsync = ref.watch(bookedSlotsProvider('${doctor.id}_$dateStr'));
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Reschedule Appointment',
                      style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                  content: SizedBox(
                    width: 320,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text('Select New Date', style: AppTypography.bodyLarge),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.iceBlue),
                          ),
                          child: SizedBox(
                            height: 240,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 320,
                                height: 340,
                                child: CalendarDatePicker(
                                  initialDate: selectedDate,
                                  firstDate: firstAllowedDate,
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                  onDateChanged: (date) {
                                    setInner(() {
                                      selectedDate = date;
                                      selectedSlot = '';
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Select Time Slot', style: AppTypography.bodyLarge),
                        const SizedBox(height: 8),
                        bookedSlotsAsync.when(
                          data: (bookedSlots) {
                            final allSlots = getSlotsForDate(selectedDate);
                            final availableSlots = allSlots
                                .where((slot) => !bookedSlots.contains(slot))
                                .toList();
                            if (availableSlots.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.iceBlue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'No slots available for this date.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumBlue),
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableSlots.map((slot) {
                                final isSelected = selectedSlot == slot;
                                return GestureDetector(
                                  onTap: () => setInner(() => selectedSlot = slot),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.deepBlue : AppColors.iceBlue,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? AppColors.deepBlue : AppColors.lightBlue,
                                      ),
                                    ),
                                    child: Text(
                                      slot,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isSelected ? AppColors.white : AppColors.darkNavy,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
                          error: (err, stack) => Text('Error loading slots', style: AppTypography.bodyLarge),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: selectedSlot.isEmpty
                          ? null
                          : () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBlue,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != true || selectedSlot.isEmpty) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(app['id'])
          .update({
        'date': dateStr,
        'slot': selectedSlot,
        'status': 1,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        container.refresh(appointmentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reschedule. Please try again.')),
        );
      }
    }
  }

  List<String> _generateFallbackSlots(DoctorModel doctor) {
    final slots = <String>[];
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

  Future<void> _cancel(BuildContext context, Map<String, dynamic> app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Appointment?',
            style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        content: Text(
          'Your appointment with ${app['doctorName']} on ${app['date']} at ${app['slot']} '
              'will be cancelled.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep it',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel Booking',
                style: AppTypography.buttonText.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(app['id'])
          .update({'status': 3});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel. Please try again.')),
        );
      }
    }
  }
}