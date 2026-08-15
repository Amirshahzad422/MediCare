import 'package:flutter/material.dart';
import '../components/records_view.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../layouts/responsive_layout.dart';

class DoctorRecordsScreen extends StatelessWidget {
  const DoctorRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return ResponsiveLayout(
      currentRoute: '/doctor-records',
      showFooter: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.deepBlue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Patient Records',
            style: AppTypography.titleLarge.copyWith(fontSize: 20, color: AppColors.darkNavy),
          ),
          centerTitle: true,
        ),
        body: RecordsView(doctorId: doctorId, doctorName: '',),
      ),
    );
  }
}
