import 'package:flutter/material.dart';
import '../models/session_data.dart';
import '../theme/app_theme.dart';

class WeeklyConsumptionChart extends StatelessWidget {
  final List<DailyIntake> weeklyIntake;

  const WeeklyConsumptionChart({
    super.key,
    required this.weeklyIntake,
  });

  @override
  Widget build(BuildContext context) {
    final maxGrams = weeklyIntake.map((e) => e.grams).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Consumption Rhythm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Daily gram intake & peak weekend session trends',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '1.4g/day avg',
                  style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart Row
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyIntake.map((intake) {
                final heightFactor = (intake.grams / (maxGrams * 1.15)).clamp(0.08, 1.0);
                final isPeak = intake.grams == maxGrams;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${intake.grams.toStringAsFixed(1)}g',
                      style: TextStyle(
                        color: isPeak ? AppColors.primary : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: 90 * heightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isPeak
                              ? [AppColors.primaryLight, AppColors.primary]
                              : intake.isWeekend
                                  ? [AppColors.primaryLight.withValues(alpha: 0.6), AppColors.primary.withValues(alpha: 0.4)]
                                  : [AppColors.surfaceElevation3, AppColors.surfaceElevation1],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPeak ? AppColors.primaryLight : AppColors.border,
                          width: 1,
                        ),
                        boxShadow: isPeak
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intake.dayName,
                      style: TextStyle(
                        color: intake.isWeekend ? Colors.white : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: intake.isWeekend ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class StrainBreakdownBar extends StatelessWidget {
  const StrainBreakdownBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Strain Type Distribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Past 30 Days',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: 52,
                    child: Container(color: AppColors.hybridTag),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 34,
                    child: Container(color: AppColors.indicaTag),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 14,
                    child: Container(color: AppColors.sativaTag),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('Hybrid', '52%', AppColors.hybridTag),
              _buildLegendItem('Indica', '34%', AppColors.indicaTag),
              _buildLegendItem('Sativa', '14%', AppColors.sativaTag),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String name, String percent, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$name: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          percent,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
