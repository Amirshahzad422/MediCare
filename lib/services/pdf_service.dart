import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a styled MediCare prescription PDF.
class PdfService {
  static Future<Uint8List> generatePrescriptionPdf(
      Map<String, dynamic> presc) async {
    final pdf = pw.Document();

    final medicines = (presc['medicines'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF052659), // deepBlue
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MediCare',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Digital Health Platform',
                          style: const pw.TextStyle(
                              fontSize: 12, color: PdfColors.grey300),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'E-Prescription',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Date: ${presc['date'] ?? _today()}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey300),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ─── Doctor & Patient info ──────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Doctor
                  pw.Expanded(
                    child: _infoBox(
                      title: 'Prescribing Doctor',
                      lines: [
                        presc['doctorName'] ?? 'Doctor',
                        presc['specialty'] ?? 'Specialist',
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Patient
                  pw.Expanded(
                    child: _infoBox(
                      title: 'Patient',
                      lines: [
                        presc['patientName'] ?? 'Patient',
                        'Patient ID: ${(presc['patientId'] ?? '').toString().substring(0, 8)}…',
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ─── Diagnosis ─────────────────────────────────────────────
              _sectionTitle('Diagnosis'),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0F8FF),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFC1E8FF), width: 1),
                ),
                child: pw.Text(
                  presc['diagnosis'] ?? 'No diagnosis noted',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 20),

              // ─── Medicines table ────────────────────────────────────────
              _sectionTitle('Prescribed Medicines'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                    color: const PdfColor.fromInt(0xFFC1E8FF), width: 1),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF052659)),
                    children: [
                      _tableHeader('Medicine'),
                      _tableHeader('Dosage'),
                      _tableHeader('Duration'),
                    ],
                  ),
                  // Data rows
                  ...medicines.asMap().entries.map((entry) {
                    final i = entry.key;
                    final med = entry.value;
                    final bg = i.isEven
                        ? const PdfColor.fromInt(0xFFFFFFFF)
                        : const PdfColor.fromInt(0xFFF0F8FF);
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _tableCell(med['name'] ?? ''),
                        _tableCell(med['dosage'] ?? ''),
                        _tableCell(med['duration'] ?? ''),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // ─── Notes ─────────────────────────────────────────────────
              if ((presc['notes'] as String?)?.isNotEmpty == true) ...[
                _sectionTitle('Doctor\'s Notes'),
                pw.SizedBox(height: 6),
                pw.Text(presc['notes'] ?? '',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 20),
              ],

              pw.Spacer(),

              // ─── Footer ────────────────────────────────────────────────
              pw.Divider(color: const PdfColor.fromInt(0xFFC1E8FF)),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Doctor\'s Signature',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 20),
                      pw.Container(
                          width: 150, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(presc['doctorName'] ?? '',
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'This is a digitally generated prescription\nfrom MediCare health platform.',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey500),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('www.medicare.health',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.blue)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoBox({required String title, required List<String> lines}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFC1E8FF)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF5483B3),
            ),
          ),
          pw.SizedBox(height: 4),
          ...lines.map(
            (l) => pw.Text(l, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: const PdfColor.fromInt(0xFF052659),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
    );
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
