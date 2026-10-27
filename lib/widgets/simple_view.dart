import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/camera_scan_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SimpleView extends StatelessWidget {
  final AppState state;

  const SimpleView({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Context Switcher & Stash Fuel Gauge
        _buildStashTelemetrySection(context),
        const SizedBox(height: 16),

        // 2. Currently In Rotation (Tactile Hero Card)
        _buildCurrentlyBurningCard(context),
        const SizedBox(height: 16),

        // 3. Scan Packaging Label Button (Camera AI Auto-Fill)
        _buildScanPackagingButton(context),
        const SizedBox(height: 16),

        // 4. Quick Vibe Jars (Tap to switch rotation)
        _buildQuickVibeJarsSection(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScanPackagingButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CameraScanService.startPackagingScan(context, state: state),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGlow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Packaging Label',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        'Photograph jar or pouch to auto-extract strain & THC',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Stash Telemetry Card
  Widget _buildStashTelemetrySection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWeight = state.simpleContext == 'weight';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with context switch pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stash Telemetry',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pill Switcher
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildPillButton(
                      label: 'Weight',
                      isActive: isWeight,
                      onTap: () => state.setSimpleContext('weight'),
                    ),
                    _buildPillButton(
                      label: 'Strains',
                      isActive: !isWeight,
                      onTap: () => state.setSimpleContext('type'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Panels
          if (isWeight)
            _buildWeightPanel(context)
          else
            _buildStrainsPanel(context),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // Weight Fuel Gauge
  Widget _buildWeightPanel(BuildContext context) {
    final totalGrams = state.totalStashRemainingGrams;
    final totalCapacity = 36.0; // Benchmark capacity
    final fillRatio = (totalGrams / totalCapacity).clamp(0.0, 1.0);
    final fillPercent = (fillRatio * 100).round();

    return Column(
      children: [
        // Circular Fuel Gauge
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _CircularGaugePainter(
                  progress: fillRatio,
                  progressColor: AppColors.primary,
                  trackColor: AppColors.surfaceElevation3,
                  strokeWidth: 9,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${totalGrams.toStringAsFixed(1)}g',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$fillPercent% FULL',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '~${state.runwayDays} Days on Deck at Current Burn Rate',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Mini Visual Bars
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  label: 'Indica',
                  value: '${state.indicaRemainingGrams.toStringAsFixed(1)}g',
                  color: AppColors.indicaTag,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  label: 'Sativa',
                  value: '${state.sativaRemainingGrams.toStringAsFixed(1)}g',
                  color: AppColors.sativaTag,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  label: 'Hybrid',
                  value: '${state.hybridRemainingGrams.toStringAsFixed(1)}g',
                  color: AppColors.hybridTag,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Strain Balance Panel
  Widget _buildStrainsPanel(BuildContext context) {
    final total = state.totalStashRemainingGrams > 0 ? state.totalStashRemainingGrams : 1.0;
    final indicaPct = ((state.indicaRemainingGrams / total) * 100).round();
    final sativaPct = ((state.sativaRemainingGrams / total) * 100).round();
    final hybridPct = (100 - indicaPct - sativaPct).clamp(0, 100);

    return Column(
      children: [
        // Proportional balance bar
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevation1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (indicaPct > 0)
                Expanded(
                  flex: math.max(1, indicaPct),
                  child: Container(color: AppColors.indicaTag),
                ),
              if (sativaPct > 0)
                Expanded(
                  flex: math.max(1, sativaPct),
                  child: Container(color: AppColors.sativaTag),
                ),
              if (hybridPct > 0)
                Expanded(
                  flex: math.max(1, hybridPct),
                  child: Container(color: AppColors.hybridTag),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail rows
        _buildStrainRow(
          title: 'Indica (Deep Relax)',
          stat: '$indicaPct% · ${state.indicaStrainCount} Strains',
          color: AppColors.indicaTag,
        ),
        const SizedBox(height: 8),
        _buildStrainRow(
          title: 'Sativa (Focus & Energy)',
          stat: '$sativaPct% · ${state.sativaStrainCount} Strains',
          color: AppColors.sativaTag,
        ),
        const SizedBox(height: 8),
        _buildStrainRow(
          title: 'Hybrid (Balanced Harmony)',
          stat: '$hybridPct% · ${state.hybridStrainCount} Strains',
          color: AppColors.hybridTag,
        ),
      ],
    );
  }

  Widget _buildStrainRow({
    required String title,
    required String stat,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stat,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Currently In Rotation Hero Card
  Widget _buildCurrentlyBurningCard(BuildContext context) {
    final active = state.activeVibeProduct;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF191E2A),
            Color(0xFF222838),
            Color(0xFF191E2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'CURRENTLY IN ROTATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  active.strength.split('·').first.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Strain Details
          Text(
            active.name,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${active.type} · ${active.description}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Action Row: Quick Log Session Button + Today Hits
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.logQuickHit();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged session with ${active.name}! Today: ${state.todayHitsCount} hits'),
                        duration: const Duration(milliseconds: 1400),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceElevation3,
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_fire_department_rounded, size: 20),
                  label: const Text(
                    'Quick Log Session',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.todayHitsCount} Hits',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Quick Vibe Jars Section
  Widget _buildQuickVibeJarsSection(BuildContext context) {
    final available = state.openProducts.take(3).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TAP JAR TO SWITCH ROTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${available.length} Ready',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: available.map((p) {
            Color accentColor = AppColors.primary;
            IconData icon = Icons.spa_rounded;
            if (p.type.toLowerCase().contains('indica')) {
              accentColor = AppColors.indicaTag;
              icon = Icons.bedtime_rounded;
            } else if (p.type.toLowerCase().contains('sativa')) {
              accentColor = AppColors.sativaTag;
              icon = Icons.bolt_rounded;
            }

            final shortName = p.name.split(' ').first;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildVibeJarCard(
                  strainId: p.id,
                  shortName: shortName,
                  gramsLeft: '${p.remainingGrams.toStringAsFixed(1)}g left',
                  icon: icon,
                  accentColor: accentColor,
                  isActive: state.activeVibeStrainId == p.id,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVibeJarCard({
    required String strainId,
    required String shortName,
    required String gramsLeft,
    required IconData icon,
    required Color accentColor,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () => state.setActiveVibeStrain(strainId),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevation2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              shortName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              gramsLeft,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Circular Fuel Gauge
class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularGaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Paint
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
