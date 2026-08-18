import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../styles/colors.dart';

class RoleGuard extends ConsumerWidget {
  final Widget child;
  final List<int> allowedRoles;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  static const _loader = Scaffold(
    backgroundColor: AppColors.white,
    body: Center(
      child: CircularProgressIndicator(color: AppColors.deepBlue),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) return _loader;
    final user = authState.asData?.value ?? FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent && route.settings.name != '/login') {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        }
      });
      return _loader;
    }

    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => _loader,
      error: (_, __) => _loader,
      data: (profile) {
        if (profile == null) return _loader;

        if (!allowedRoles.contains(profile.role)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final route = ModalRoute.of(context);
            final targetRoute = profile.role == 2 ? '/doctor-dashboard' : '/dashboard';
            if (route != null && route.isCurrent && route.settings.name != targetRoute) {
              Navigator.pushReplacementNamed(context, targetRoute);
            }
          });
          return _loader;
        }

        return child;
      },
    );
  }
}