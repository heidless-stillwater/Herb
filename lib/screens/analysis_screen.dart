import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/consumption_chart.dart';

class AnalysisScreen extends StatefulWidget {
  final AppState state;

  const AnalysisScreen({
    super.key,
    required this.state,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedRange = '30D';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final products = state.products;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumption & Telemetry',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Predictive analytics & pattern recognition',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time Horizon Selector Pills
              Row(
                children: ['7D', '30D', '90D', '1 Year', 'All Time'].map((range) {
                  final isSelected = _selectedRange == range;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRange = range),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceElevation3 : AppColors.surfaceElevation1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            range,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 4 Key Metric KPI Summary Tiles (2x2 Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildKpiCard(
                    'Monthly Rate',
                    '38.5g',
                    '-8.2% vs last cycle',
                    Icons.trending_down_rounded,
                    Colors.greenAccent,
                  ),
                  _buildKpiCard(
                    'Daily Burn Avg',
                    '${state.avgDailyBurn}g',
                    'Stable intake rhythm',
                    Icons.speed_rounded,
                    AppColors.primaryLight,
                  ),
                  _buildKpiCard(
                    'Stash Runway',
                    '${state.runwayDays} Days',
                    '${state.totalStashRemainingGrams.toStringAsFixed(1)}g total reserve',
                    Icons.hourglass_top_rounded,
                    AppColors.primary,
                  ),
                  _buildKpiCard(
                    'Stash Valuation',
                    '\$${state.totalSpendMonth.toStringAsFixed(0)}',
                    '\$8.31 / g average',
                    Icons.account_balance_wallet_outlined,
                    Colors.amberAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly Consumption Rhythm Bar Chart
              WeeklyConsumptionChart(weeklyIntake: state.weeklyIntake),
              const SizedBox(height: 16),

              // Strain Breakdown
              const StrainBreakdownBar(),
              const SizedBox(height: 20),

              // Pattern Recognition Engine Module
              Text(
                'Identified Ritual Patterns',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Column(
                children: state.patternInsights.map((insight) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    insight.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevation1,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      insight.metric,
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                insight.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Predictive Future Projection Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2230), AppColors.surfaceElevation2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Predictive Stash Depletion Forecast',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Based on your 1.28g/day 30-day rolling burn rate, your current 46.5g reserve will sustain sessions for 19 more days.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevation1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.event_available_rounded, color: AppColors.primaryLight, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Exhaustion Date: Nov 12, 2026',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Recommended Re-order Window: Nov 5 - Nov 8',
                                  style: TextStyle(color: AppColors.primaryLight, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Purchase History Table / Ledger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Purchase History Ledger',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${products.length} Records',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 18,
                    headingRowHeight: 40,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    headingTextStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    columns: const [
                      DataColumn(label: Text('DATE')),
                      DataColumn(label: Text('STRAIN')),
                      DataColumn(label: Text('SOURCE')),
                      DataColumn(label: Text('QTY')),
                      DataColumn(label: Text('PRICE')),
                      DataColumn(label: Text('RATING')),
                    ],
                    rows: products.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text(_dateFormat.format(p.datePurchased))),
                          DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(p.source.split(',')[0])),
                          DataCell(Text('${p.totalGrams.toStringAsFixed(0)}g')),
                          DataCell(Text('\$${p.price.toStringAsFixed(0)}')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(p.rating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: accentColor.withValues(alpha: 0.9), fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
