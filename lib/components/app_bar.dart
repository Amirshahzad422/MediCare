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
    return Center(
      child: Text(
        'MediCare',
        style: isDark
            ? AppTypography.titleLarge.copyWith(fontSize: 20, color: AppColors.white)
            : AppTypography.titleLarge.copyWith(fontSize: 20),
      ),
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

  static const List<String> rootRoutes = [
    '/',
    '/doctor-dashboard',
    '/doctors',
    '/appointments',
    '/pharmacy',
    '/prescriptions',
    '/orders',
    '/profile',
    '/notifications',
    '/reviews',
    '/about',
    '/contact',
    '/settings',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final showBack = Navigator.of(context).canPop() && !rootRoutes.contains(currentRoute);

    return Material(
      color: AppColors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: EdgeInsets.only(left: isWide ? 20 : 8, right: 20),
          child: Row(
            children: [
              if (!isWide) ...[
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.deepBlue, size: 28),
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.deepBlue, size: 28),
                    onPressed: () => _openDrawer(scaffoldContext ?? context),
                  ),
                Expanded(
                  child: Center(
                    child: _buildTitle(context, currentRoute, false),
                  ),
                ),
                if (user != null)
                  _NotificationIcon(
                    onPressed: onNotify ?? () {},
                    ref: ref,
                  )
                else
                  const SizedBox(width: 8),
              ],
              if (isWide) ...[
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.deepBlue, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/'),
                  child: const BrandLogo(isDark: false),
                ),
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
                if (user == null) ...[
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      'Login',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.deepBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _LoginCta(onTap: () => Navigator.pushNamed(context, '/register')),
                ] else ...[
                  _NotificationIcon(
                    onPressed: onNotify ?? () {},
                    ref: ref,
                  ),
                  _AvatarButton(
                    isDark: false,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext ctx) {
    Scaffold.of(ctx).openDrawer();
  }

  Widget _buildTitle(BuildContext context, String route, bool isDark) {
    if (route == '/' || route == '/doctor-dashboard' || route.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, route.isEmpty ? '/' : route),
        child: BrandLogo(isDark: isDark),
      );
    }

    String titleText = 'MediCare';
    switch (route) {
      case '/appointments':
        titleText = 'Appointments';
        break;
      case '/doctors':
        titleText = 'Doctors';
        break;
      case '/pharmacy':
        titleText = 'Pharmacy';
        break;
      case '/profile':
        titleText = 'Profile';
        break;
      case '/doctor-records':
        titleText = 'Patient Records';
        break;
      case '/about':
        titleText = 'About Us';
        break;
      case '/contact':
        titleText = 'Contact Us';
        break;
      case '/settings':
        titleText = 'Settings';
        break;
      case '/dashboard':
        titleText = 'Dashboard';
        break;
      case '/notifications':
        titleText = 'Notifications';
        break;
      default:
        if (route.startsWith('/')) {
          final stripped = route.substring(1);
          if (stripped.isNotEmpty) {
            titleText = stripped.split('-').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
          }
        }
    }

    return Text(
      titleText,
      textAlign: TextAlign.center,
      style: AppTypography.titleLarge.copyWith(
        fontSize: 16,
        color: isDark ? AppColors.white : AppColors.deepBlue,
      ),
    );
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
          icon: const Icon(Icons.notifications_none, color: AppColors.deepBlue),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: IgnorePointer(
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
                ? AppColors.iceBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.isActive ? AppColors.deepBlue : AppColors.grey),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.isActive ? AppColors.deepBlue : AppColors.grey,
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