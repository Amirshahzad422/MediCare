import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/bottom_nav_bar.dart';
import '../components/app_drawer.dart';
import '../components/app_bar.dart';
import 'patient_home_screen.dart';
import 'appointments_screen.dart';
import 'pharmacy_screen.dart';
import 'prescriptions_screen.dart';
import 'profile_screen.dart';
import 'doctor_dashboard_screen.dart';
import '../providers/appointments_provider.dart';
import '../providers/doctor_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  bool _initializedArgs = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _availabilitySynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['initialIndex'] != null) {
        _currentIndex = args['initialIndex'] as int;
        if (_currentIndex == 1) {
          Future.microtask(() {
            ref.invalidate(appointmentsStreamProvider);
          });
        }
      }
      _initializedArgs = true;
    }
  }

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
        final isDoctor = role == 2;
        // print'👤 Dashboard: user role = $role, isDoctor = $isDoctor');

        if (isDoctor) {
          final doctorProfileAsync = ref.watch(doctorProfileProvider);
          return doctorProfileAsync.when(
            data: (doctor) {
              // print'📄 Doctor profile from doctors collection: $doctor');
              if (doctor == null || !doctor.isOnboardingComplete) {
                // print'❌ Onboarding incomplete, redirecting to /doctor-onboarding');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/doctor-onboarding');
                });
                return const Scaffold(
                  backgroundColor: AppColors.white,
                  body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
                );
              }
              // print'✅ Onboarding complete, building dashboard UI');
              if (!_availabilitySynced) {
                _availabilitySynced = true;
                Future.microtask(() => ref.read(profileServiceProvider).syncDoctorAvailability());
              }
              return _buildDashboardUI(role, isDoctor, context);
            },
            loading: () => const Scaffold(
              backgroundColor: AppColors.white,
              body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
            ),
            error: (err, stack) => Scaffold(
              backgroundColor: AppColors.white,
              body: Center(child: Text('Error loading profile', style: AppTypography.bodyLarge)),
            ),
          );
        } else {
          final userDocAsync = ref.watch(userDocProvider);
          return userDocAsync.when(
            data: (userDoc) {
              if (userDoc == null || userDoc['isOnboardingComplete'] != true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/patient-onboarding');
                });
                return const Scaffold(
                  backgroundColor: AppColors.white,
                  body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
                );
              }
              return _buildDashboardUI(role, isDoctor, context);
            },
            loading: () => const Scaffold(
              backgroundColor: AppColors.white,
              body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
            ),
            error: (err, stack) => Scaffold(
              backgroundColor: AppColors.white,
              body: Center(child: Text('Error loading profile', style: AppTypography.bodyLarge)),
            ),
          );
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
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

  Widget _buildDashboardUI(int role, bool isDoctor, BuildContext context) {
    final List<Widget> pages = isDoctor
        ? const [
      DoctorDashboardScreen(),
      AppointmentsScreen(),
      ProfileScreen(),
    ]
        : const [
      PatientHomeScreen(),
      AppointmentsScreen(),
      PharmacyScreen(),
      PrescriptionsScreen(),
      ProfileScreen(),
    ];

    final String currentRoute = isDoctor
        ? ['/doctor-dashboard', '/appointments', '/profile'][_currentIndex.clamp(0, 2)]
        : ['/', '/appointments', '/pharmacy', '/prescriptions', '/profile'][_currentIndex.clamp(0, 4)];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // Prevent pop, go to first tab instead
        }
        return true; // Allow pop, exits app
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Builder(
            builder: (ctx) => CustomAppBar(
              currentRoute: currentRoute,
              scaffoldContext: ctx,
              onNotify: () => Navigator.pushNamed(context, '/notifications'),
            ),
          ),
        ),
        drawer: AppDrawer(currentRoute: currentRoute),
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
            if (index == 1) {
              ref.invalidate(appointmentsStreamProvider);
            } else if (index == 0 && isDoctor) {
              final user = ref.read(userProfileProvider).value;
              if (user != null) {
                ref.invalidate(doctorAppointmentsProvider(user.uid));
              }
            }
          },
        ),
      ),
    );
  }
}