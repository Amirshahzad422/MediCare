import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import 'app_bar.dart';

/// Shared footer shown on wide screens within the responsive layout.
class AppFooter extends StatelessWidget {
  final String currentRoute;

  const AppFooter({super.key, this.currentRoute = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkNavy,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          const spacing = SizedBox(height: 16);
          final columns = <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(isDark: true),
                const SizedBox(height: 12),
                Text(
                  'MediCare connects patients with\ncertified doctors for online\nconsultations, prescriptions &\nmedicine delivery.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightBlue,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerHeading('Quick Links'),
                spacing,
                _footerLink('Home', onTap: () => Navigator.pushNamed(context, '/')),
                _footerLink('Doctors', onTap: () => Navigator.pushNamed(context, '/doctors')),
                _footerLink('Pharmacy', onTap: () => Navigator.pushNamed(context, '/pharmacy')),
                _footerLink('Appointments', onTap: () => Navigator.pushNamed(context, '/appointments')),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerHeading('Company'),
                spacing,
                _footerLink('About Us', onTap: () => Navigator.pushNamed(context, '/about')),
                _footerLink('Contact', onTap: () => Navigator.pushNamed(context, '/contact')),
                _footerLink('FAQ', onTap: () => Navigator.pushNamed(context, '/faq')),
                _footerLink('Blog', onTap: () => Navigator.pushNamed(context, '/blog')),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerHeading('Contact Info'),
                spacing,
                const _InfoRow(icon: Icons.place_outlined, text: '730 Mission St, San Francisco'),
                const _InfoRow(icon: Icons.phone_outlined, text: '+1 (800) 123-4567'),
                const _InfoRow(icon: Icons.mail_outline, text: 'care@medicare.com'),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    _SocialIcon(icon: Icons.facebook, label: 'Facebook'),
                    SizedBox(width: 8),
                    _SocialIcon(icon: Icons.camera_alt_outlined, label: 'Instagram'),
                    SizedBox(width: 8),
                    _SocialIcon(icon: Icons.chat_bubble_outline, label: 'Twitter'),
                  ],
                ),
              ],
            ),
          ];

          final footerContent = [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.map((c) => Expanded(child: c)).toList(),
              )
            else
              ...columns.map(
                (c) => Padding(padding: const EdgeInsets.only(bottom: 24), child: c),
              ),
            const Divider(color: AppColors.mediumBlue),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2026 MediCare. All rights reserved. Built with care by the MediCare team.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.grey),
              ),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: footerContent,
          );
        },
      ),
    );
  }

  Widget _footerHeading(String text) {
    return Text(
      text,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _footerLink(String label, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.iceBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.lightBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.iceBlue),
      ),
    );
  }
}