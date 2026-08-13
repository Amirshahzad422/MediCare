import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import 'prescription_writer_sheet.dart';
import '../services/call_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class DoctorAppointmentCard extends StatefulWidget {
  final Map<String, dynamic> app;
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

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final status = app['status'] ?? 'upcoming';

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
                  app['slot']?.toString().split(' ').first ?? '--:--',
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
                      app['patientName'] ?? 'Patient',
                      style: AppTypography.titleLarge.copyWith(fontSize: 15),
                    ),
                    Text(
                      '${app['type'] ?? 'Video'} • ${app['slot']}',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          if (status == 'upcoming' || status == 'completed') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (status == 'upcoming')
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
                if (status == 'upcoming') const SizedBox(width: 8),
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
          ...widget.app,
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
          final specialty = docAsync.value?['specialty'] ?? 'General Physician';
          final photo = docAsync.value?['photo'] ?? '';

          return PrescriptionWriterSheet(
            doctorName: widget.doctorName,
            specialty: specialty,
            doctorPhoto: photo,
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
        ? AppColors.error
        : AppColors.deepBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}