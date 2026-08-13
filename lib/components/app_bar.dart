import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class BrandLogo extends StatelessWidget {
  final bool isDark;

  const BrandLogo({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark ? AppColors.iceBlue : AppColors.deepBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.medical_services,
            size: 20,
            color: isDark ? AppColors.deepBlue : AppColors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'MediCare',
          style: isDark
              ? AppTypography.titleLarge.copyWith(fontSize: 20, color: AppColors.white)
              : AppTypography.titleLarge.copyWith(fontSize: 20),
        ),
      ],
    );
  }
}

class CustomAppBar extends ConsumerWidget {
  final String currentRoute;
  final VoidCallback? onNotify;
  final BuildContext? scaffoldContext;

  const CustomAppBar({
    super.key,
    required this.currentRoute,
    this.onNotify,
    this.scaffoldContext,
  });

  static const List<(String, String, IconData)> navItems = [
    ('/', 'Home', Icons.home_outlined),
    ('/doctors', 'Doctors', Icons.local_hospital_outlined),
    ('/appointments', 'Appointments', Icons.calendar_month_outlined),
    ('/pharmacy', 'Pharmacy', Icons.local_pharmacy_outlined),
    ('/about', 'About', Icons.info_outline),
    ('/contact', 'Contact', Icons.mail_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Material(
      color: AppColors.deepBlue,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.white, size: 28),
                  onPressed: () => _openDrawer(scaffoldContext ?? context),
                ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/'),
                child: const BrandLogo(isDark: true),
              ),
              if (isWide) ...[
                const SizedBox(width: 32),
                Expanded(
                  child: Row(
                    children: [
                      for (final (route, label, icon) in navItems)
                        _NavLink(
                          label: label,
                          icon: icon,
                          isActive: currentRoute == route,
                          onTap: () => Navigator.pushNamed(context, route),
                        ),
                    ],
                  ),
                ),
              ] else
                const Spacer(),
              if (isWide && user == null) ...[
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Login',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _LoginCta(onTap: () => Navigator.pushNamed(context, '/register')),
              ],
              if (isWide && user != null) ...[
                _NotificationIcon(
                  onPressed: onNotify ?? () {},
                  ref: ref,
                ),
                _AvatarButton(
                  isDark: true,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
              if (!isWide && user != null)
                _NotificationIcon(
                  onPressed: onNotify ?? () {},
                  ref: ref,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext ctx) {
    Scaffold.of(ctx).openDrawer();
  }
}

class _NotificationIcon extends ConsumerWidget {
  final VoidCallback onPressed;
  final WidgetRef ref;

  const _NotificationIcon({
    required this.onPressed,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final count = ref.watch(unreadNotificationsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoginCta extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          'Get Started',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AvatarButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.iceBlue : AppColors.deepBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mediumBlue,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: const Icon(Icons.person, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive || _hovered
                ? AppColors.mediumBlue.withOpacity(0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: AppColors.iceBlue),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.isActive ? AppColors.white : AppColors.iceBlue,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}