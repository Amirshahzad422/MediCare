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
        body: RecordsView(doctorId: doctorId, doctorName: '',),
      ),
    );
  }
}
