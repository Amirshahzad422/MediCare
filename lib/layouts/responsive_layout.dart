import 'package:flutter/material.dart';
import '../components/app_bar.dart';
import '../components/app_drawer.dart';
import '../components/footer.dart';
import '../styles/colors.dart';

class ResponsiveLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final bool showFooter;

  const ResponsiveLayout({
    super.key,
    required this.currentRoute,
    required this.child,
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Builder(
          builder: (scaffoldContext) => CustomAppBar(
            currentRoute: currentRoute,
            scaffoldContext: scaffoldContext,
          ),
        ),
      ),
      drawer: AppDrawer(currentRoute: currentRoute),
      body: Column(
        children: [
          Expanded(child: child),
          if (isWide && showFooter) const AppFooter(),
        ],
      ),
    );
  }
}