import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/bottom_nav_bar.dart';
import 'patient_home_screen.dart';
import 'appointments_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Center(
              child: Text(
                'Session Expired. Please Login Again.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
            ),
          );
        }

        final role = user.role;
        final List<Widget> pages = role == 2
            ? [
                const Scaffold(
                  body: Center(
                    child: Text('Doctor Dashboard (Coming Soon!)'),
                  ),
                ),
                const Scaffold(
                  body: Center(
                    child: Text('Doctor Appointments (Coming Soon!)'),
                  ),
                ),
                const Scaffold(
                  body: Center(
                    child: Text('Doctor Profile (Coming Soon!)'),
                  ),
                ),
              ]
            : [
                const PatientHomeScreen(),
                const AppointmentsScreen(),
                const Scaffold(
                  body: Center(
                    child: Text('Patient Profile (Coming Soon!)'),
                  ),
                ),
              ];

        return Scaffold(
          backgroundColor: AppColors.white,
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: CustomBottomNavBar(
            role: role,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.deepBlue,
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Text(
            'Error loading dashboard',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}