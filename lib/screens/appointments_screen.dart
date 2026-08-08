import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/appointments_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  // Guard temporarily disabled - always allow joining for demo
  // bool _canJoinConsultation(String dateStr, String slotStr) {
  //   try {
  //     final now = DateTime.now();
  //     final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  //
  //     if (dateStr != todayStr) {
  //       return false;
  //     }
  //
  //     final parts = slotStr.trim().split(' ');
  //     if (parts.length != 2) return false;
  //     final timeParts = parts[0].split(':');
  //     if (timeParts.length != 2) return false;
  //
  //     int hour = int.parse(timeParts[0]);
  //     final minute = int.parse(timeParts[1]);
  //     final amPm = parts[1].toUpperCase();
  //
  //     if (amPm == 'PM' && hour < 12) {
  //       hour += 12;
  //     }
  //     if (amPm == 'AM' && hour == 12) {
  //       hour = 0;
  //     }
  //
  //     final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
  //     final difference = now.difference(slotDateTime).inMinutes;
  //
  //     return difference >= -10 && difference <= 30;
  //   } catch (_) {
  //     return true;
  //   }
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'My Appointments',
            style: AppTypography.titleLarge.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: AppColors.deepBlue,
            unselectedLabelColor: AppColors.lightBlue,
            indicatorColor: AppColors.deepBlue,
            labelStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTypography.bodyMedium,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: appointmentsAsync.when(
          data: (appointments) {
            final upcoming = appointments
                .where((app) => app['status'] == 'upcoming')
                .toList();
            final past = appointments
                .where((app) => app['status'] != 'upcoming')
                .toList();

            return TabBarView(
              children: [
                _buildAppointmentsList(context, upcoming),
                _buildAppointmentsList(context, past),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.deepBlue,
            ),
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

  Widget _buildAppointmentsList(BuildContext context, List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.lightBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: AppTypography.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final app = list[index];
        final isUpcoming = app['status'] == 'upcoming';
        final dateStr = app['date'] ?? '';
        final slotStr = app['slot'] ?? '';

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceBlue, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      app['doctorPhoto'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: AppColors.iceBlue,
                          child: const Icon(Icons.person, color: AppColors.deepBlue),
                        );
                      },
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
                        Text(
                          app['specialty'] ?? '',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUpcoming ? AppColors.iceBlue : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (app['status'] ?? '').toUpperCase(),
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 10,
                        color: isUpcoming ? AppColors.deepBlue : AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: AppColors.mediumBlue),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.mediumBlue),
                      const SizedBox(width: 4),
                      Text(
                        slotStr,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              if (isUpcoming) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Guard temporarily disabled - always allow joining for demo
                    // if (_canJoinConsultation(dateStr, slotStr)) {
                    Navigator.pushNamed(
                      context,
                      '/video-call',
                      arguments: app,
                    );
                    // } else {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(
                    //       content: Text(
                    //         'You can only join at the scheduled time: $dateStr at $slotStr',
                    //       ),
                    //     ),
                    //   );
                    // }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Join Consultation',
                    style: AppTypography.buttonText.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}