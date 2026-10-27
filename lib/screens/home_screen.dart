import '../widgets/stillwater_sync_modal.dart';
import 'package:flutter/material.dart';
import '../services/camera_scan_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/stash_carousel_card.dart';
import '../widgets/source_card.dart';
import '../widgets/simple_view.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onNavigateToExplorer;

  const HomeScreen({
    super.key,
    required this.state,
    required this.onNavigateToExplorer,
  });

  @override
  Widget build(BuildContext context) {
    final openProducts = state.openProducts;
    final isSimple = state.viewMode == 'simple';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar with Dual-Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'herb',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'the c*nt with a blunt',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Stillwater Sovereign Suite Status & Sync Icon
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: state.authService.isAuthenticated
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: IconButton(
                      icon: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Icon(
                            Icons.castle_rounded,
                            size: 18,
                            color: state.authService.isAuthenticated ? AppColors.primary : AppColors.textMuted,
                          ),
                          if (state.authService.isAuthenticated)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      tooltip: 'Stillwater Suite Cloud Sync (herb-db-0)',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => StillwaterSyncModal(state: state),
                        );
                      },
                    ),
                  ),
                  // Dual-Mode Toggle Pill (Simple vs Detail)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(
                          label: 'Simple',
                          icon: Icons.grid_view_rounded,
                          isActive: isSimple,
                          onTap: () => state.setViewMode('simple'),
                        ),
                        _buildModeButton(
                          label: 'Detail',
                          icon: Icons.view_agenda_rounded,
                          isActive: !isSimple,
                          onTap: () => state.setViewMode('detail'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stillwater Suite Status Banner
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: state.authService.isAuthenticated
                      ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                      : AppColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.authService.isAuthenticated
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.authService.isAuthenticated ? Icons.castle_rounded : Icons.offline_bolt_outlined,
                      color: state.authService.isAuthenticated ? Colors.greenAccent : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                state.authService.isAuthenticated ? 'Stillwater Sovereign Suite' : 'Offline Guest Mode',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (state.authService.isStillwaterSuperUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber, width: 0.6),
                                  ),
                                  child: const Text('SU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.authService.isAuthenticated
                                ? (state.authService.email ?? 'Connected · herb-db-0')
                                : 'Local storage only · herb-db-0 not synced',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: state.authService.isAuthenticated ? AppColors.error : AppColors.primary,
                      ),
                      onPressed: () {
                        if (state.authService.isAuthenticated) {
                          state.authService.signOut();
                          state.setBypassAuth(false);
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => StillwaterSyncModal(state: state),
                          );
                        }
                      },
                      child: Text(
                        state.authService.isAuthenticated ? 'Sign Out' : 'Sign In',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Active View: Simple or Detail
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isSimple
                    ? SimpleView(
                        key: const ValueKey('simple_view'),
                        state: state,
                      )
                    : _buildDetailView(
                        context,
                        openProducts,
                        onNavigateToExplorer,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detail View (Full original stash display)
  Widget _buildDetailView(
    BuildContext context,
    List dynamicProducts,
    VoidCallback onNavigateToExplorer,
  ) {
    return Column(
      key: const ValueKey('detail_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        GestureDetector(
          onTap: onNavigateToExplorer,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevation2,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search strains, brands, sources...',
                    style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () => CameraScanService.startPackagingScan(context, state: state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Scan',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Quick Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All',
              'Indica · Relax',
              'Sativa · Energy',
              'Hybrid · Balanced',
              'Extracts & Rosin'
            ].map((category) {
              final normalized = category.split(' ')[0];
              final isSelected = state.selectedType == (normalized == 'All' ? 'All' : normalized);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(category),
                  onPressed: () {
                    state.setSelectedType(normalized == 'All' ? 'All' : normalized);
                    onNavigateToExplorer();
                  },
                  backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceElevation2,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Favorite Stash & Top Products
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Favorite Stash',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onNavigateToExplorer,
              child: Text(
                'Manage (${dynamicProducts.length})',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel of Stash Cards
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: dynamicProducts.length,
            itemBuilder: (context, index) {
              final product = dynamicProducts[index];
              return StashCarouselCard(
                product: product,
                onTap: onNavigateToExplorer,
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Curated Sources & Brands
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Trusted Sources & Brands',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onNavigateToExplorer,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: state.brandSources.map((source) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SourceCard(
                source: source,
                onTap: onNavigateToExplorer,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Recent Activity & Consumption Summary Tile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surfaceElevation2, Color(0xFF161A24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Recent Intake & Activity',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '-12% vs last week',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '7-Day Intake Rate: 1.4g / day average across all active strains. Latest acquisition: Pineapple Express (1oz) from Apex Botanicals.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onNavigateToExplorer,
                      icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      label: const Text('Explore Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
