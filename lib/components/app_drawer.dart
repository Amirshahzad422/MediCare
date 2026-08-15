import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'schedule_view.dart';
import 'records_view.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final profileAsync = ref.watch(userProfileProvider);
    final role = profileAsync.value?.role ?? 0;
    final isDoctor = role == 2;
    final doctorName = profileAsync.value?.name ?? 'Doctor';

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.deepBlue),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      size: 26,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MediCare',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        user?.email ?? 'Not signed in',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.iceBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (!isDoctor) _tile(context, Icons.home_outlined, 'Home', '/', ref),
                  if (!isDoctor) _tile(context, Icons.local_hospital_outlined, 'Doctors', '/doctors', ref),
                  if (isDoctor) _tile(context, Icons.space_dashboard_outlined, 'Dashboard', '/doctor-dashboard', ref),
                  if (isDoctor) _tile(context, Icons.calendar_month_outlined, 'My Schedule', '', ref,
                      onTapOverride: () => _openScheduleModal(context, doctorName, ref)),
                  if (isDoctor) _tile(context, Icons.folder_shared_outlined, 'Patient Records', '', ref,
                      onTapOverride: () => _openRecordsModal(context, doctorName)),
                  _tile(context, Icons.calendar_month_outlined, 'Appointments', '/appointments', ref),
                  if (!isDoctor) _tile(context, Icons.local_pharmacy_outlined, 'Pharmacy', '/pharmacy', ref),
                  if (!isDoctor) _tile(context, Icons.description_outlined, 'Prescriptions', '/prescriptions', ref),
                  if (!isDoctor) _tile(context, Icons.receipt_long_outlined, 'Orders', '/orders', ref),
                  _tile(context, Icons.rate_review_outlined, 'Reviews', '/reviews', ref),
                  _tile(context, Icons.person_outline, 'Profile', '/profile', ref),
                  _tile(context, Icons.notifications_outlined, 'Notifications', '/notifications', ref),
                  const Divider(height: 24, color: AppColors.iceBlue),
                  _tile(context, Icons.info_outline, 'About Us', '/about', ref),
                  _tile(context, Icons.mail_outline, 'Contact', '/contact', ref),
                  _tile(context, Icons.help_outline, 'FAQ', '/faq', ref),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: user == null
                    ? ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Login'),
                )
                    : OutlinedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context,
      IconData icon,
      String label,
      String route,
      WidgetRef ref, {
        VoidCallback? onTapOverride,
      }) {
    final isActive = currentRoute == route && route.isNotEmpty;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.deepBlue : AppColors.mediumBlue,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isActive ? AppColors.deepBlue : AppColors.darkNavy,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.iceBlue.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        if (onTapOverride != null) {
          onTapOverride();
        } else if (currentRoute != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }

  void _openScheduleModal(BuildContext context, String doctorName, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ScheduleView(
                doctorName: doctorName,
                onAvailabilityChanged: (v) async {
                  await ref
                      .read(profileServiceProvider)
                      .setDoctorAvailability(doctorName, v);
                  ref.invalidate(userDocProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecordsModal(BuildContext context, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Patient Prescriptions',
                style: AppTypography.titleLarge.copyWith(fontSize: 20),
              ),
            ),
            Expanded(child: RecordsView(doctorName: doctorName, doctorId: '',)),
          ],
        ),
      ),
    );
  }
}