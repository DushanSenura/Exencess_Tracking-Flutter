import 'package:flutter/material.dart';

import '../../models/finance_feature_models.dart';
import '../widgets/charts.dart';
import '../widgets/finance_cards.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.budgetUsage,
    required this.monthlyBudget,
    required this.topCategories,
    required this.weeklyExpenses,
    required this.netWorth,
    required this.endOfMonthForecast,
    required this.budgetScore,
    required this.savingsStreakWeeks,
    required this.personalizedTips,
    required this.currencySymbol,
    required this.accountBalanceBreakdown,
    required this.goalSavedByAccount,
    required this.goalSavingsBreakdownByAccount,
    required this.selectedBudgetHealthGoalName,
    required this.selectedBudgetHealthGoalProgress,
    required this.selectedBudgetHealthGoalSaved,
    required this.selectedBudgetHealthGoalTarget,
    required this.visibleWidgetIds,
  });

  final double balance;
  final double income;
  final double expense;
  final double budgetUsage;
  final double monthlyBudget;
  final Map<String, double> topCategories;
  final List<double> weeklyExpenses;
  final double netWorth;
  final double endOfMonthForecast;
  final double budgetScore;
  final int savingsStreakWeeks;
  final List<String> personalizedTips;
  final String currencySymbol;
  final List<({String accountId, String accountName, double amount})>
  accountBalanceBreakdown;
  final Map<String, double> goalSavedByAccount;
  final Map<String, List<({String goalName, double amount})>>
  goalSavingsBreakdownByAccount;
  final String? selectedBudgetHealthGoalName;
  final double? selectedBudgetHealthGoalProgress;
  final double? selectedBudgetHealthGoalSaved;
  final double? selectedBudgetHealthGoalTarget;
  final List<DashboardWidgetId> visibleWidgetIds;

  Widget _staggerIn({required int order, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 260 + (order * 70)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        final double dy = (1 - value) * 14;
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
    );
  }

  void _showSelectedAccountSummary(
    BuildContext context,
    ({String accountId, String accountName, double amount}) account,
  ) {
    final double accountGoalsSaved = goalSavedByAccount[account.accountId] ?? 0;
    final List<({String goalName, double amount})> goalSavingsBreakdown =
        goalSavingsBreakdownByAccount[account.accountId] ??
        <({String goalName, double amount})>[];
    final double freeAfterGoals = account.amount - accountGoalsSaved;
    final Color tone = freeAfterGoals >= 0
        ? const Color(0xFF0E9F6E)
        : const Color(0xFFD64545);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  account.accountName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Selected account summary',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Text(
                  'Main Points',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text('Money in selected account'),
                        trailing: Text(
                          '$currencySymbol${account.amount.toStringAsFixed(2)}',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text('Money saved in goals'),
                        trailing: Text(
                          '$currencySymbol${accountGoalsSaved.toStringAsFixed(2)}',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text('Balance after goals'),
                        trailing: Text(
                          '$currencySymbol${freeAfterGoals.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: tone,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Goal Breakdown (Sub points)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        if (goalSavingsBreakdown.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No goals available.'),
                          )
                        else
                          ...goalSavingsBreakdown.map((goal) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: <Widget>[
                                  const Text('• '),
                                  Expanded(child: Text(goal.goalName)),
                                  Text(
                                    '$currencySymbol${goal.amount.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountBalanceBreakdown(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account Balances',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (accountBalanceBreakdown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('No account balances available.'),
                  )
                else
                  ...accountBalanceBreakdown.map((item) {
                    final bool isNegative = item.amount < 0;
                    final Color amountColor = isNegative
                        ? const Color(0xFFD64545)
                        : const Color(0xFF0E9F6E);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.accountName),
                      subtitle: const Text('Tap to view goals comparison'),
                      onTap: () => _showSelectedAccountSummary(context, item),
                      trailing: Text(
                        '$currencySymbol${item.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> top = topCategories.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });

    bool show(DashboardWidgetId id) => visibleWidgetIds.contains(id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (show(DashboardWidgetId.currentBalance)) ...<Widget>[
          _staggerIn(
            order: 0,
            child: FinanceCard(
              title: 'Current Balance',
              value: balance,
              icon: Icons.account_balance_wallet,
              currencySymbol: currencySymbol,
              onTap: () => _showAccountBalanceBreakdown(context),
              color: balance >= 0
                  ? const Color(0xFF0E9F6E)
                  : const Color(0xFFD64545),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (show(DashboardWidgetId.incomeExpense)) ...<Widget>[
          _staggerIn(
            order: 1,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: MiniFinanceCard(
                    label: 'Income',
                    value: income,
                    icon: Icons.arrow_downward,
                    tone: const Color(0xFF0E9F6E),
                    currencySymbol: currencySymbol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MiniFinanceCard(
                    label: 'Expense',
                    value: expense,
                    icon: Icons.arrow_upward,
                    tone: const Color(0xFFD64545),
                    currencySymbol: currencySymbol,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (show(DashboardWidgetId.netWorthForecast)) ...<Widget>[
          _staggerIn(
            order: 2,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: MiniFinanceCard(
                    label: 'Net Worth',
                    value: netWorth,
                    icon: Icons.account_balance,
                    tone: const Color(0xFF1E429F),
                    currencySymbol: currencySymbol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MiniFinanceCard(
                    label: 'Forecast',
                    value: endOfMonthForecast,
                    icon: Icons.trending_up,
                    tone: const Color(0xFF7E3AF2),
                    currencySymbol: currencySymbol,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (show(DashboardWidgetId.budgetHealth))
          _staggerIn(
            order: 3,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    if (selectedBudgetHealthGoalName == null)
                      Text(
                        'Choose a goal from the Goals page to display here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else ...<Widget>[
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: <InlineSpan>[
                            TextSpan(
                              text: selectedBudgetHealthGoalName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedBudgetHealthGoalProgress != null &&
                          selectedBudgetHealthGoalSaved != null &&
                          selectedBudgetHealthGoalTarget != null) ...<Widget>[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: selectedBudgetHealthGoalProgress!.clamp(0, 1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saved $currencySymbol${selectedBudgetHealthGoalSaved!.toStringAsFixed(0)} / $currencySymbol${selectedBudgetHealthGoalTarget!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (show(DashboardWidgetId.budgetHealth)) const SizedBox(height: 20),
        if (show(DashboardWidgetId.gamification))
          _staggerIn(
            order: 4,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gamification',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Budget Score: ${budgetScore.toStringAsFixed(0)} / 100',
                    ),
                    Text('Savings Streak: $savingsStreakWeeks week(s)'),
                  ],
                ),
              ),
            ),
          ),
        if (show(DashboardWidgetId.gamification)) const SizedBox(height: 20),
        if (show(DashboardWidgetId.personalizedTips))
          _staggerIn(
            order: 5,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Personalized Tips',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...personalizedTips.take(3).map((String tip) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('- $tip'),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        if (show(DashboardWidgetId.personalizedTips))
          const SizedBox(height: 20),
        if (show(DashboardWidgetId.weeklyTrend))
          _staggerIn(
            order: 6,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '30-Day Expense Trend',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: WeeklyExpenseLineChart(data: weeklyExpenses),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (show(DashboardWidgetId.weeklyTrend)) const SizedBox(height: 20),
        if (show(DashboardWidgetId.topCategories))
          _staggerIn(
            order: 7,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Top Spending Categories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (top.isEmpty)
                      const Text('No spending data yet for this month.')
                    else
                      ...top.take(4).map((MapEntry<String, double> e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: <Widget>[
                              Expanded(child: Text(e.key)),
                              Text(
                                '$currencySymbol${e.value.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
