import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/doctor_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'loader.dart';

class DashboardStatsCard extends ConsumerWidget {
  final String doctorId;
  const DashboardStatsCard({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(doctorId));

    return appointmentsAsync.when(
      data: (appointments) {
        final completed = appointments.where((app) {
          final raw = app['status'];
          final status = raw is int ? raw : (int.tryParse(raw?.toString() ?? '') ?? -1);
          return status == 2;
        }).toList();
        final totalEarnings = completed.fold<double>(0, (sum, app) => sum + ((app['amount'] ?? 0) as num).toDouble());

        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayCount = appointments.where((app) => app['date'] == todayStr).length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deepBlue, AppColors.darkNavy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.deepBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Earnings', style: AppTypography.bodyMedium.copyWith(color: AppColors.iceBlue)),
                  const Icon(Icons.account_balance_wallet, color: AppColors.iceBlue, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text('\$${totalEarnings.toStringAsFixed(2)}', style: AppTypography.displayLarge.copyWith(color: AppColors.white, fontSize: 32)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatMiniItem(title: 'Consultations', value: '${completed.length} Done'),
                  _StatMiniItem(title: 'Today\'s Queue', value: '$todayCount Patients'),
                ],
              )
            ],
          ),
        );
      },
      loading: () => const SkeletonBox(height: 180, width: double.infinity),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _StatMiniItem extends StatelessWidget {
  final String title;
  final String value;
  const _StatMiniItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}