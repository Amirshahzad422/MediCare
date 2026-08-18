import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/prescription_provider.dart';
import '../services/pdf_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../utils/pdf_downloader.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
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
                    'No prescriptions yet',
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prescriptions issued after your consultations\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: prescriptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final presc = prescriptions[index];
              return _PrescriptionCard(presc: presc);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.deepBlue),
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

class _PrescriptionCard extends StatefulWidget {
  final Map<String, dynamic> presc;
  const _PrescriptionCard({required this.presc});

  @override
  State<_PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<_PrescriptionCard> {
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final presc    = widget.presc;
    final medicines = presc['medicines'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    presc['date'] ?? '',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Rx',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 24),

          Text(
            'Diagnosis:',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            presc['diagnosis'] ?? 'No diagnosis noted',
            style: AppTypography.bodyMedium,
          ),

          const SizedBox(height: 14),

          Text(
            'Prescribed Medicines:',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(color: AppColors.deepBlue),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Medicine',
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Dosage',
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Frequency',
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          ...medicines.asMap().entries.map((entry) {
            final i   = entry.key;
            final med = entry.value as Map<String, dynamic>? ?? {};
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: i.isEven
                  ? AppColors.iceBlue.withValues(alpha: 0.2)
                  : AppColors.white,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      med['name'] ?? '',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(flex: 2, child: Text(med['dosage'] ?? '', style: AppTypography.bodyMedium)),
                  Expanded(flex: 2, child: Text(med['frequency'] ?? '', style: AppTypography.bodyMedium)),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatingPdf ? null : () => _downloadPdf(context),
                  icon: _generatingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(
                    _generatingPdf ? 'Generating PDF…' : 'Download PDF',
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/pharmacy',
                      arguments: medicines,
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(
                    'Order Medicines',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.deepBlue, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepBlue,
                    side: const BorderSide(color: AppColors.deepBlue),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    setState(() => _generatingPdf = true);
    try {
      final presc = widget.presc;
      final prescId = presc['id']?.toString();
      final filename =
          'MediCare_Prescription_${presc['date'] ?? 'rx'}.pdf';

      final cachedUrl = presc['pdfUrl']?.toString();

      Uint8List pdfBytes;

      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(cachedUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch cached PDF (${response.statusCode})');
        }
        pdfBytes = response.bodyBytes;
      } else {
        pdfBytes = await PdfService.generatePrescriptionPdf(presc);

        if (prescId != null && prescId.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance
                .ref('prescriptions/$prescId.pdf');
            final uploadTask = await ref.putData(
              pdfBytes,
              SettableMetadata(contentType: 'application/pdf'),
            );
            final downloadUrl = await uploadTask.ref.getDownloadURL();

            await FirebaseFirestore.instance
                .collection('prescriptions')
                .doc(prescId)
                .update({'pdfUrl': downloadUrl});

            presc['pdfUrl'] = downloadUrl;
          } catch (_) {
          }
        }
      }

      await downloadPrescriptionPdf(pdfBytes, filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }
}