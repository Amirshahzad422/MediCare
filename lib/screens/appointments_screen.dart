import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/appointments_provider.dart';
import '../models/appointment_model.dart';
import '../providers/auth_provider.dart';
import '../components/appointment_card.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  static Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.deepBlue;
      case 2:
        return Colors.green;
      case 3:
        return AppColors.error;
      default:
        return AppColors.mediumBlue;
    }
  }

  static Color _statusBg(int status) {
    switch (status) {
      case 1:
        return AppColors.iceBlue;
      case 2:
        return Colors.green.shade50;
      case 3:
        return Colors.red.shade50;
      default:
        return AppColors.iceBlue;
    }
  }

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

  static const List<({String label, List<int> statuses})> _groups = [
    (label: 'All', statuses: []),
    (label: 'Upcoming', statuses: [1]),
    (label: 'Past', statuses: [2]),
    (label: 'Cancelled', statuses: [3]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);
    final isDoctor = ref.watch(userProfileProvider).value?.role == 2;

    int initialTabIndex = 0;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['appointmentsTabIndex'] != null) {
      initialTabIndex = args['appointmentsTabIndex'] as int;
    }

    return DefaultTabController(
      initialIndex: initialTabIndex,
      length: _groups.length,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: appointmentsAsync.when(
          data: (appointments) {
            final grouped = <String, List<AppointmentModel>>{};
            for (final group in _groups) {
              final groupKey = group.label;
              grouped[groupKey] = appointments
                  .where((app) {
                final status = AppointmentsScreen.parseStatus(app.status);
                if (group.label == 'All') return true;
                return group.statuses.contains(status);
              })
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  color: AppColors.white,
                  child: Center(
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.deepBlue,
                      unselectedLabelColor: AppColors.lightBlue,
                      indicatorColor: AppColors.deepBlue,
                      labelStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: AppTypography.bodyMedium,
                      tabs: _groups.map((group) {
                        final count = grouped[group.label]?.length ?? 0;
                        final label = count > 0
                            ? '${group.label} ($count)'
                            : group.label;
                        return Tab(text: label);
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: _groups.map((group) {
                      final list = grouped[group.label] ?? [];
                      return _buildList(
                        context,
                        list,
                        groupLabel: group.label,
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
      List<AppointmentModel> list, {
        required String groupLabel,
        required bool isDoctor,
      }) {
    if (list.isEmpty) {
      final showBookButton = (groupLabel == 'Pending' || groupLabel == 'All') && !isDoctor;
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
              'No appointments',
              style: AppTypography.bodyLarge,
            ),
            if (showBookButton) ...[
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
      itemBuilder: (ctx, i) {
        final app = list[i];
        final status = AppointmentsScreen.parseStatus(app.status);
        return AppointmentCard(
          app: app,
          status: status,
          statusColor: _statusColor(status),
          statusBg: _statusBg(status),
          isDoctor: isDoctor,
        );
      },
    );
  }
}