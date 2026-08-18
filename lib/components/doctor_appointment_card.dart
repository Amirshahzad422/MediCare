import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/profile_provider.dart';
import 'prescription_writer_sheet.dart';
import '../services/call_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

import '../models/appointment_model.dart';

class DoctorAppointmentCard extends StatefulWidget {
  final AppointmentModel app;
  final String doctorName;

  const DoctorAppointmentCard({
    super.key,
    required this.app,
    required this.doctorName,
  });

  @override
  State<DoctorAppointmentCard> createState() => _DoctorAppointmentCardState();
}

class _DoctorAppointmentCardState extends State<DoctorAppointmentCard> {
  bool _joiningCall = false;

  static int parseStatus(dynamic raw) {
    if (raw is int) return raw;
    final str = raw?.toString().toLowerCase();
    if (str == '1' || str == 'pending' || str == 'accepted' || str == 'rescheduled') {
      return 1;
    }
    if (str == '2' || str == 'completed') {
      return 2;
    }
    if (str == '3' || str == 'cancelled') {
      return 3;
    }
    return int.tryParse(str ?? '') ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final status = parseStatus(app.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.iceBlue.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  app.slot.split(' ').first,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.deepBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.patientName,
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                    ),
                    Text(
                      '${app.type} • ${app.slot}',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (status == 1 || status == 2) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (status == 1) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _joiningCall ? null : () => _joinCall(context),
                      icon: _joiningCall
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.video_call, size: 18),
                      label: Text(
                        _joiningCall ? 'Joining…' : 'Join Call',
                        style: AppTypography.buttonText.copyWith(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBlue,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Cancel',
                    child: OutlinedButton(
                      onPressed: () => _cancel(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(44, 40),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.cancel_outlined, size: 18),
                    ),
                  ),
                ],
                if (status == 2)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPrescriptionWriter(context),
                      icon: const Icon(Icons.edit_document, size: 18),
                      label: Text(
                        'Write Rx',
                        style: AppTypography.buttonText.copyWith(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iceBlue,
                        foregroundColor: AppColors.deepBlue,
                        elevation: 0,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _joinCall(BuildContext context) async {
    setState(() => _joiningCall = true);
    try {
      final callId = await CallService().ensureCallRoom(widget.app);
      await CallService()
          .joinCall(callId, isDoctor: true, name: widget.doctorName);
      if (!context.mounted) return;
      Navigator.pushNamed(
        context,
        '/video-call',
        arguments: {
          ...widget.app.toMap(),
          'id': widget.app.id,
          'callId': callId,
          'isDoctor': true,
        },
      );
    } finally {
      if (mounted) setState(() => _joiningCall = false);
    }
  }

  void _openPrescriptionWriter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final docAsync = ref.watch(userDocProvider);
          final rawName = docAsync.value?['name'] ?? widget.doctorName;
          final doctorName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';
          final specialty = docAsync.value?['specialty'] ?? 'General Physician';
          final photo = docAsync.value?['photo'] ?? '';

          return PrescriptionWriterSheet(
            doctorName: doctorName,
            specialty: specialty,
            doctorPhoto: photo,
            prefilledPatientId: widget.app.patientId,
            prefilledPatientName: widget.app.patientName,
          );
        },
      ),
    );
  }

  Widget _statusBadge(int status) {
    final color = status == 2
        ? Colors.green
        : status == 3
        ? AppColors.error
        : AppColors.deepBlue;

    String statusText = '';
    if (status == 1) statusText = 'UPCOMING';
    else if (status == 2) statusText = 'PAST';
    else if (status == 3) statusText = 'CANCELLED';
    else statusText = 'UNKNOWN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Appointment?',
            style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        content: Text(
          'Your appointment with ${widget.app.patientName} on ${widget.app.date} at ${widget.app.slot} '
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
          .doc(widget.app.id)
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