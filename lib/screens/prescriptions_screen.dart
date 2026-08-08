import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prescription_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Prescriptions',
          style: AppTypography.titleLarge.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: prescriptionsAsync.when(
        data: (prescriptions) {
          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.lightBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No prescriptions found',
                    style: AppTypography.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20.0),
            itemCount: prescriptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final presc = prescriptions[index];
              final medicines = presc['medicines'] as List<dynamic>? ?? [];

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                presc['doctorName'] ?? 'Doctor',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge.copyWith(fontSize: 16),
                              ),
                              Text(
                                presc['specialty'] ?? 'Specialist',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          presc['date'] ?? '',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Diagnosis:',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      presc['diagnosis'] ?? 'No diagnosis noted',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Prescribed Medicines:',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...medicines.map((med) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                med['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${med['dosage'] ?? ''} (${med['duration'] ?? ''})',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/pharmacy',
                          arguments: medicines,
                        );
                      },
                      icon: const Icon(Icons.shopping_bag, size: 18),
                      label: const Text('Order Prescribed Medicines'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBlue,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.deepBlue,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load prescriptions',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}