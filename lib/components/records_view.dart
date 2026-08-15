import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prescription_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'empty_state.dart';
import 'loader.dart';

class RecordsView extends ConsumerWidget {
  final String doctorId;
  const RecordsView({super.key, required this.doctorId, required String doctorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsForDoctorProvider(doctorId));
    return prescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) return const EmptyState(icon: Icons.folder_open_outlined, title: 'No records yet');
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: prescriptions.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = prescriptions[index];
            final meds = (p['medicines'] as List<dynamic>?) ?? [];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.iceBlue, width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['patientName'] ?? 'Patient', style: AppTypography.titleLarge.copyWith(fontSize: 15)),
                      Text(p['date'] ?? '', style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${p['diagnosis'] ?? 'Consultation'}', style: AppTypography.bodyLarge.copyWith(fontSize: 13)),
                  const SizedBox(height: 8),
                  ...meds.take(3).map((med) => Text('• ${med['name']} (${med['dosage']})', style: AppTypography.bodyMedium.copyWith(fontSize: 12))),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (_, __) => const Text('Error loading records'),
    );
  }
}