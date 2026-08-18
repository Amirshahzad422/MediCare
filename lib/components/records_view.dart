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
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.iceBlue, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.iceBlue.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.deepBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['patientName'] ?? 'Patient', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              '${p['patientAge'] ?? 'N/A'} yrs • ${p['patientGender'] ?? 'N/A'}',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.mediumBlue, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(p['date'] ?? '', style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Diagnosis: ${p['diagnosis'] ?? 'Consultation'}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.deepBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (meds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...meds.take(3).map((med) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2, right: 6),
                                child: Icon(Icons.medication, size: 14, color: AppColors.mediumBlue),
                              ),
                              Expanded(
                                child: Text(
                                  '${med['name']} - ${med['dosage']}',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
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