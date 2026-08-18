import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/button.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../providers/profile_provider.dart';

class PrescriptionWriterSheet extends ConsumerStatefulWidget {
  final String doctorName;
  final String specialty;
  final String doctorPhoto;
  final String? prefilledPatientId;
  final String? prefilledPatientName;

  const PrescriptionWriterSheet({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.doctorPhoto,
    this.prefilledPatientId,
    this.prefilledPatientName,
  });

  @override
  ConsumerState<PrescriptionWriterSheet> createState() => _PrescriptionWriterSheetState();
}

class _PrescriptionWriterSheetState extends ConsumerState<PrescriptionWriterSheet> {
  String? _selectedPatientId;
  String? _selectedPatientName;

  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<({
  TextEditingController name,
  TextEditingController dosage,
  TextEditingController frequency,
  TextEditingController duration
  })> _medRows = [];

  bool _isSaving = false;
  late final Stream<QuerySnapshot> _appointmentsStream;

  bool get _isFormValid {
    final diagnosis = _diagnosisController.text.trim();
    final hasValidMedicine = _medRows.any((row) => row.name.text.trim().isNotEmpty);
    return _selectedPatientId != null &&
        diagnosis.isNotEmpty &&
        hasValidMedicine;
  }

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.prefilledPatientId;
    _selectedPatientName = widget.prefilledPatientName;
    _appointmentsStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();
    _addMedicineRow(); 
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    for (final row in _medRows) {
      row.name.dispose();
      row.dosage.dispose();
      row.frequency.dispose();
      row.duration.dispose();
    }
    super.dispose();
  }

  void _addMedicineRow() {
    final nameCtrl = TextEditingController()
      ..addListener(_onFormChanged);
    final dosageCtrl = TextEditingController();
    final frequencyCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

    setState(() {
      _medRows.add((
      name: nameCtrl,
      dosage: dosageCtrl,
      frequency: frequencyCtrl,
      duration: durationCtrl,
      ));
    });
  }

  void _onFormChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    final validMeds = _medRows
        .where((row) => row.name.text.trim().isNotEmpty)
        .map((row) => {
      'name': row.name.text.trim(),
      'dosage': row.dosage.text.trim(),
      'frequency': row.frequency.text.trim(),
      'duration': row.duration.text.trim(),
      'notes': '',
    })
        .toList();

    if (!_isFormValid) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    final dateStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final docAsync = ref.read(userDocProvider);
    final rawName = docAsync.value?['name'] ?? widget.doctorName;
    final doctorName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';
    final specialty = docAsync.value?['specialty'] ?? widget.specialty;
    final photo = docAsync.value?['photo'] ?? widget.doctorPhoto;

    String patientAge = 'N/A';
    String patientGender = 'N/A';

    try {
      if (_selectedPatientId != null) {
        final patientSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedPatientId)
            .get();
        final patientData = patientSnap.data();
        if (patientData != null) {
          patientAge = patientData['age']?.toString() ?? 'N/A';
          patientGender = patientData['gender'] ?? 'N/A';
        }
      }

      await FirebaseFirestore.instance.collection('prescriptions').add({
        'patientId': _selectedPatientId,
        'patientName': _selectedPatientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'doctorId': user?.uid ?? '',
        'doctorName': doctorName,
        'specialty': specialty,
        'doctorPhoto': photo,
        'date': dateStr,
        'diagnosis': _diagnosisController.text.trim(),
        'medicines': validMeds,
        'notes': _notesController.text.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription issued successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save prescription.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Digital Prescription',
                  style: AppTypography.titleLarge.copyWith(fontSize: 20)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.darkNavy),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Patient'),

                  if (widget.prefilledPatientId != null)
                    TextFormField(
                      initialValue: widget.prefilledPatientName ?? 'Patient',
                      readOnly: true,
                      style: AppTypography.bodyLarge,
                      decoration: _inputDecoration('Selected patient', Icons.person_outline),
                    )
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: _appointmentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: LinearProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'No completed consultations found yet. Complete an appointment first to write a prescription.',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: Colors.orange.shade800),
                            ),
                          );
                        }

                        final allDocs = snapshot.data!.docs;
                        final docs = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final rawStatus = data['status'];
                          return rawStatus == 2 ||
                              rawStatus?.toString() == '2' ||
                              rawStatus?.toString().toLowerCase() == 'completed';
                        }).toList();

                        if (docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'No completed consultations found yet. Complete an appointment first to write a prescription.',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: Colors.orange.shade800),
                            ),
                          );
                        }

                        final Map<String, String> completedPatients = {};
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final pId = data['patientId'] ?? '';
                          final pName = data['patientName'] ?? 'Patient';
                          if (pId.isNotEmpty) {
                            completedPatients[pId] = pName;
                          }
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedPatientId,
                          isExpanded: true,
                          hint: Text('Choose a patient...',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                          decoration: _inputDecoration('Select patient',
                              Icons.person_outline),
                          items: completedPatients.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value,
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPatientId = val;
                              _selectedPatientName = completedPatients[val];
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  _label('Diagnosis'),
                  TextField(
                    controller: _diagnosisController,
                    style: AppTypography.bodyLarge,
                    decoration: _inputDecoration('e.g. Acute Bronchitis',
                        Icons.health_and_safety_outlined),
                    onChanged: (_) => _onFormChanged(),
                  ),
                  const SizedBox(height: 16),
                  _label("Doctor's Notes (optional)"),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: AppTypography.bodyLarge,
                    decoration: _inputDecoration('Additional instructions...',
                        Icons.note_outlined),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Medicines',
                          style:
                          AppTypography.titleLarge.copyWith(fontSize: 16)),
                      TextButton.icon(
                        onPressed: _addMedicineRow,
                        icon: const Icon(Icons.add, size: 18,
                            color: AppColors.deepBlue),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  ..._medRows.asMap().entries.map((entry) {
                    final row = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.iceBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: row.name,
                            style: AppTypography.bodyLarge,
                            decoration: _inputDecoration('Medicine name',
                                Icons.medication),
                            onChanged: (_) => _onFormChanged(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: row.dosage,
                                  style: AppTypography.bodyLarge,
                                  decoration: _inputDecoration('Dosage',
                                      Icons.layers_outlined),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: row.frequency,
                                  style: AppTypography.bodyLarge,
                                  decoration: _inputDecoration('Freq',
                                      Icons.schedule),
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SharedButton(
            label: 'Issue Prescription',
            icon: Icons.check_circle_outline,
            isLoading: _isSaving,
            onPressed: (_isFormValid && !_isSaving) ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.darkNavy,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium,
        prefixIcon: Icon(icon, color: AppColors.mediumBlue, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
      );
}