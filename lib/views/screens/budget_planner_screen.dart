import 'package:flutter/material.dart';

class BudgetPlannerScreen extends StatelessWidget {
  const BudgetPlannerScreen({
    super.key,
    required this.categoryBudgets,
    required this.dailyCategoryBudgets,
    required this.weeklyCategoryBudgets,
    required this.categoryExpenses,
    required this.dailyCategoryExpenses,
    required this.weeklyCategoryExpenses,
    required this.currencySymbol,
  });

  final Map<String, double> categoryBudgets;
  final Map<String, double> dailyCategoryBudgets;
  final Map<String, double> weeklyCategoryBudgets;
  final Map<String, double> categoryExpenses;
  final Map<String, double> dailyCategoryExpenses;
  final Map<String, double> weeklyCategoryExpenses;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
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
                  'Daily Budget Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Set today\'s spending guardrails by category.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...dailyCategoryBudgets.entries.map((MapEntry<String, double> e) {
          final double spent = dailyCategoryExpenses[e.key] ?? 0;
          final double usage = e.value <= 0 ? 0 : (spent / e.value).clamp(0, 1);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('${e.key} (Daily)')),
                      Text(
                        '$currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${e.value.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: usage),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Weekly Budget Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Track this week to avoid end-of-month surprises.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...weeklyCategoryBudgets.entries.map((MapEntry<String, double> e) {
          final double spent = weeklyCategoryExpenses[e.key] ?? 0;
          final double usage = e.value <= 0 ? 0 : (spent / e.value).clamp(0, 1);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('${e.key} (Weekly)')),
                      Text(
                        '$currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${e.value.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: usage),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        ...categoryBudgets.entries.map((MapEntry<String, double> e) {
          final double spent = categoryExpenses[e.key] ?? 0;
          final double usage = e.value <= 0 ? 0 : (spent / e.value).clamp(0, 1);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: Text('${e.key} (Monthly)')),
                      Text(
                        '$currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${e.value.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: usage),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
