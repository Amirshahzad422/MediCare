import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../services/call_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  static Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return AppColors.deepBlue;
      case 'rescheduled':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.mediumBlue;
    }
  }

  static Color _statusBg(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade50;
      case 'accepted':
        return AppColors.iceBlue;
      case 'rescheduled':
        return Colors.purple.shade50;
      case 'completed':
        return Colors.green.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return AppColors.iceBlue;
    }
  }

  static const List<String> _statuses = [
    'pending',
    'accepted',
    'rescheduled',
    'completed',
    'cancelled'
  ];

  static String _displayName(String status) {
    if (status == 'accepted') return 'Upcoming';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);
    final isDoctor = ref.watch(userProfileProvider).value?.role == 2;

    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: appointmentsAsync.when(
          data: (appointments) {
            final grouped = <String, List<Map<String, dynamic>>>{};
            for (final status in _statuses) {
              grouped[status] = appointments
                  .where((app) => (app['status'] ?? '').toString() == status)
                  .toList()
                ..sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  color: AppColors.white,
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.deepBlue,
                    unselectedLabelColor: AppColors.lightBlue,
                    indicatorColor: AppColors.deepBlue,
                    labelStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: AppTypography.bodyMedium,
                    tabs: _statuses.map((status) {
                      final count = grouped[status]?.length ?? 0;
                      final label = count > 0
                          ? '${_displayName(status)} ($count)'
                          : _displayName(status);
                      return Tab(text: label);
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: _statuses.map((status) {
                      final list = grouped[status] ?? [];
                      return _buildList(
                        context,
                        list,
                        status: status,
                        isDoctor: isDoctor,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.deepBlue),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load appointments',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context,
      List<Map<String, dynamic>> list, {
        required String status,
        required bool isDoctor,
      }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.lightBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_displayName(status).toLowerCase()} appointments',
              style: AppTypography.bodyLarge,
            ),
            if (status == 'pending' && !isDoctor) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/doctors'),
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Book a Consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => _AppointmentCard(
        app: list[i],
        status: status,
        statusColor: _statusColor(status),
        statusBg: _statusBg(status),
        isDoctor: isDoctor,
      ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> app;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final bool isDoctor;

  const _AppointmentCard({
    required this.app,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.isDoctor,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _joiningCall = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final dateStr = app['date'] ?? '';
    final slotStr = app['slot'] ?? '';
    final type = app['type'] ?? 'Video';

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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  app['doctorPhoto'] ?? '',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.iceBlue,
                    child: const Icon(Icons.person, color: AppColors.deepBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['doctorName'] ?? '',
                      style: AppTypography.titleLarge.copyWith(fontSize: 16),
                    ),
                    Text(app['specialty'] ?? 'Consultation', style: AppTypography.bodyMedium),
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
                  widget.status.toUpperCase(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 10,
                    color: widget.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          if (widget.status == 'pending' || widget.status == 'accepted') ...[
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
          if (widget.status == 'completed') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text('Consultation Completed',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.green)),
              ],
            ),
          ],
        ],
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
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '';
    final slots = [
      '09:00 AM', '10:00 AM', '11:00 AM',
      '12:00 PM', '02:00 PM', '03:00 PM',
      '04:00 PM', '05:00 PM',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) => AlertDialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Reschedule Appointment',
                style: AppTypography.titleLarge.copyWith(fontSize: 18)),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select New Date', style: AppTypography.bodyLarge),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setInner(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightBlue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.deepBlue),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: AppTypography.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Time Slot', style: AppTypography.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
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
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedSlot.isEmpty ? null : () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true || selectedSlot.isEmpty) return;

    try {
      final dateStr =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(app['id'])
          .update({'date': dateStr, 'slot': selectedSlot, 'status': 'rescheduled'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reschedule. Please try again.')),
        );
      }
    }
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
          .update({'status': 'cancelled'});
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