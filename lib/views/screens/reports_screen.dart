import 'package:flutter/material.dart';

import '../../models/finance_feature_models.dart';
import '../widgets/charts.dart';

enum ReportSummaryPeriod { date, week, month }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.income,
    required this.expense,
    required this.dateTrendData,
    required this.weekTrendData,
    required this.monthTrendData,
    required this.netWorth,
    required this.endOfMonthForecast,
    required this.goalInsights,
    required this.smartBillAlerts,
    required this.currencySymbol,
  });

  final double income;
  final double expense;
  final Map<String, double> dateTrendData;
  final Map<String, double> weekTrendData;
  final Map<String, double> monthTrendData;
  final double netWorth;
  final double endOfMonthForecast;
  final List<GoalInsight> goalInsights;
  final List<String> smartBillAlerts;
  final String currencySymbol;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportSummaryPeriod _selectedPeriod = ReportSummaryPeriod.date;

  Map<String, double> get _selectedCategoryData {
    switch (_selectedPeriod) {
      case ReportSummaryPeriod.date:
        return widget.dateTrendData;
      case ReportSummaryPeriod.week:
        return widget.weekTrendData;
      case ReportSummaryPeriod.month:
        return widget.monthTrendData;
    }
  }

  String get _selectedPeriodLabel {
    switch (_selectedPeriod) {
      case ReportSummaryPeriod.date:
        return 'Date';
      case ReportSummaryPeriod.week:
        return 'Week';
      case ReportSummaryPeriod.month:
        return 'Month';
    }
  }

  String _formatMoney(double value) {
    return '${widget.currencySymbol}${value.toStringAsFixed(2)}';
  }

  Color _netColor(double value) {
    if (value > 0) {
      return const Color(0xFF0E9F6E);
    }
    if (value < 0) {
      return const Color(0xFFD64545);
    }
    return Colors.grey;
  }

  List<MapEntry<String, double>> _sortedCategories(Map<String, double> source) {
    final List<MapEntry<String, double>> items = source.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });
    return items;
  }

  Widget _kpiTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double savingsRate = widget.income <= 0
        ? 0
        : ((widget.income - widget.expense) / widget.income) * 100;
    final double net = widget.income - widget.expense;
    final Map<String, double> selectedCategoryData = _selectedCategoryData;
    final double selectedPeriodExpense = selectedCategoryData.values.fold(
      0,
      (double sum, double value) => sum + value,
    );
    final List<MapEntry<String, double>> topCategories = _sortedCategories(
      selectedCategoryData,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Report Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyze your spending by period',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: <Widget>[
                    _kpiTile(
                      context,
                      label: 'Income',
                      value: _formatMoney(widget.income),
                      icon: Icons.south,
                      valueColor: const Color(0xFF0E9F6E),
                    ),
                    _kpiTile(
                      context,
                      label: 'Expense',
                      value: _formatMoney(widget.expense),
                      icon: Icons.north,
                      valueColor: const Color(0xFFD64545),
                    ),
                    _kpiTile(
                      context,
                      label: 'Net',
                      value: _formatMoney(net),
                      icon: Icons.balance,
                      valueColor: _netColor(net),
                    ),
                    _kpiTile(
                      context,
                      label: '$_selectedPeriodLabel Spend',
                      value: _formatMoney(selectedPeriodExpense),
                      icon: Icons.pie_chart_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Savings Rate: ${savingsRate.toStringAsFixed(1)}%'),
                Text(
                  'Net: ${_formatMoney(net)}',
                  style: TextStyle(
                    color: _netColor(net),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (savingsRate.clamp(0, 100)) / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Forecast & Net Worth',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Projected end-of-month: ${widget.currencySymbol}${widget.endOfMonthForecast.toStringAsFixed(2)}',
                ),
                Text(
                  'Net Worth: ${widget.currencySymbol}${widget.netWorth.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Category Trends',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Selected period: $_selectedPeriodLabel'),
                Text('Categories: ${selectedCategoryData.length}'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: selectedCategoryData.isEmpty
                      ? const Center(
                          child: Text('No category spending for this period.'),
                        )
                      : ExpensePieChart(
                          data: selectedCategoryData,
                          currencySymbol: widget.currencySymbol,
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Top Categories ($_selectedPeriodLabel)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (topCategories.isEmpty)
                  const Text('No expense categories yet.')
                else
                  ...topCategories.take(5).toList().asMap().entries.map((
                    MapEntry<int, MapEntry<String, double>> entry,
                  ) {
                    final int rank = entry.key + 1;
                    final MapEntry<String, double> item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 24, child: Text('$rank.')),
                          Expanded(child: Text(item.key)),
                          Text(_formatMoney(item.value)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Savings Goal Intelligence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (widget.goalInsights.isEmpty)
                  const Text('No goals yet.')
                else
                  ...widget.goalInsights.take(4).map((GoalInsight insight) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${insight.goalName}: ${insight.monthsToGoal} month(s), ${_formatMoney(insight.requiredMonthlyContribution)}/month',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Smart Bill Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (widget.smartBillAlerts.isEmpty)
                  const Text('No due-soon or overdue bills right now.')
                else
                  ...widget.smartBillAlerts.take(4).map((String alert) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('- $alert'),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
