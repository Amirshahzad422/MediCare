import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/doctor_provider.dart';
import 'doctor_appointment_card.dart';
import 'empty_state.dart';
import 'loader.dart';

class TodayAppointmentsList extends ConsumerWidget {
  final String doctorId;
  final String doctorName;
  const TodayAppointmentsList({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(doctorId));

    return appointmentsAsync.when(
      data: (appointments) {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final today = appointments.where((app) => app.date == todayStr).toList();

        if (today.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available,
            title: 'No appointments today',
            subtitle: 'Enjoy your free time!',
          );
        }

        return Column(
          children: today.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoctorAppointmentCard(app: app, doctorName: doctorName),
          )).toList(),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (_, __) => const Text('Error loading appointments'),
    );
  }
}