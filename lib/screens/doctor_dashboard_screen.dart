import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/dashboard_stats_card.dart';
import '../components/quick_action_card.dart';
import '../components/today_appointments_list.dart';
import '../components/schedule_view.dart';
import '../components/records_view.dart';
import '../components/prescription_writer_sheet.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const Center(child: Text('Please log in as a doctor.'));
        final doctorName = profile.name;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(doctorAppointmentsProvider(doctorName)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,', style: AppTypography.bodyMedium),
                            Text('Dr. $doctorName', style: AppTypography.titleLarge.copyWith(fontSize: 24)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.iceBlue, width: 2),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: AppColors.iceBlue,
                            child: Icon(Icons.medical_services, color: AppColors.deepBlue),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 28),

                    DashboardStatsCard(doctorName: doctorName),
                    const SizedBox(height: 28),

                    IntrinsicHeight( // <-- ADD THIS
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch, // <-- ADD THIS
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.calendar_month_outlined,
                              title: 'My Schedule',
                              subtitle: 'Manage availability',
                              onTap: () => _openScheduleModal(context, doctorName, ref),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.folder_shared_outlined,
                              title: 'Patient Records',
                              subtitle: 'View prescriptions',
                              onTap: () => _openRecordsModal(context, doctorName),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today\'s Appointments', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                        TextButton(
                          onPressed: () => ref.refresh(doctorAppointmentsProvider(doctorName)),
                          child: const Text('Refresh', style: TextStyle(color: AppColors.deepBlue)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TodayAppointmentsList(doctorName: doctorName),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
          onPressed: () => _openPrescriptionWriter(doctorName, profile.role),
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          elevation: 4,
          child: const Icon(Icons.edit_note, size: 28),
        ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue))),
      error: (err, stack) => const Scaffold(body: Center(child: Text('Failed to load dashboard'))),
    );
  }

  void _openScheduleModal(BuildContext context, String doctorName, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: ScheduleView(doctorName: doctorName, onAvailabilityChanged: (v) async {
                await ref.read(profileServiceProvider).setDoctorAvailability(doctorName, v);
                ref.invalidate(userDocProvider);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecordsModal(BuildContext context, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Patient Prescriptions', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
            ),
            Expanded(child: RecordsView(doctorName: doctorName)),
          ],
        ),
      ),
    );
  }

  void _openPrescriptionWriter(String doctorName, int role) {
    ref.read(userDocProvider.future).then((doc) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PrescriptionWriterSheet(
          doctorName: doctorName,
          specialty: doc?['specialty'] ?? 'General Physician',
          doctorPhoto: doc?['photo'] ?? '',
        ),
      );
    });
  }
}