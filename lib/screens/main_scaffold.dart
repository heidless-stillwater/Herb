import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'explorer_screen.dart';
import 'analysis_screen.dart';
import 'news_screen.dart';

class MainScaffold extends StatefulWidget {
  final AppState state;

  const MainScaffold({
    super.key,
    required this.state,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final screens = [
      HomeScreen(
        state: state,
        onNavigateToExplorer: () => state.setTab(1),
      ),
      ExplorerScreen(
        state: state,
      ),
      AnalysisScreen(
        state: state,
      ),
      NewsScreen(
        state: state,
      ),
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480), // Mobile frame container
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: screens[state.currentTab],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevation1,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxWidth: 480),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', state.currentTab == 0),
                _buildNavItem(1, Icons.inventory_2_rounded, 'Products', state.currentTab == 1),
                _buildNavItem(2, Icons.analytics_rounded, 'Analysis', state.currentTab == 2),
                _buildNavItem(3, Icons.science_rounded, 'News', state.currentTab == 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () => widget.state.setTab(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
