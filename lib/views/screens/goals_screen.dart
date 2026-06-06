import 'package:flutter/material.dart';

import '../../models/savings_goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({
    super.key,
    required this.goals,
    required this.currencySymbol,
    required this.selectedHomeGoalName,
    required this.onSendCashToGoal,
    required this.onDeleteGoal,
    required this.onSelectHomeGoal,
  });

  final List<SavingsGoal> goals;
  final String currencySymbol;
  final String? selectedHomeGoalName;
  final ValueChanged<int> onSendCashToGoal;
  final ValueChanged<int> onDeleteGoal;
  final ValueChanged<String> onSelectHomeGoal;

  Widget _staggerIn({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (index * 70)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        final double dy = (1 - value) * 12;
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
    );
  }

  Widget _buildGoalCard(
    BuildContext context, {
    required SavingsGoal g,
    required int originalIndex,
    required bool isCompleted,
    required int animationIndex,
  }) {
    return _staggerIn(
      index: animationIndex,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isCompleted ? null : () => onSendCashToGoal(originalIndex),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        g.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Completed',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    IconButton(
                      tooltip: selectedHomeGoalName == g.name
                          ? 'Selected for Home'
                          : 'Show this goal on Home',
                      onPressed: () => onSelectHomeGoal(g.name),
                      icon: Icon(
                        selectedHomeGoalName == g.name
                            ? Icons.home
                            : Icons.home_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete goal',
                      onPressed: () => onDeleteGoal(originalIndex),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Saved $currencySymbol${g.currentAmount.toStringAsFixed(0)} of $currencySymbol${g.targetAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: g.progress),
                const SizedBox(height: 8),
                Text(
                  'Deadline: ${g.deadline.day}/${g.deadline.month}/${g.deadline.year}',
                ),
                const SizedBox(height: 6),
                Text(
                  isCompleted
                      ? 'Goal completed. Great work!'
                      : 'Tap this goal to send cash',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  selectedHomeGoalName == g.name
                      ? 'Showing on Home page'
                      : 'Tap home icon to show this on Home page',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(child: Text('No goals yet. Add one to get started.'));
    }

    final List<MapEntry<int, SavingsGoal>> activeGoals =
        <MapEntry<int, SavingsGoal>>[];
    final List<MapEntry<int, SavingsGoal>> completedGoals =
        <MapEntry<int, SavingsGoal>>[];

    for (int i = 0; i < goals.length; i++) {
      final SavingsGoal goal = goals[i];
      if (goal.progress >= 1) {
        completedGoals.add(MapEntry<int, SavingsGoal>(i, goal));
      } else {
        activeGoals.add(MapEntry<int, SavingsGoal>(i, goal));
      }
    }

    final List<Widget> children = <Widget>[];
    int animationIndex = 0;

    if (activeGoals.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Active Goals',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );

      for (final MapEntry<int, SavingsGoal> item in activeGoals) {
        children.add(
          _buildGoalCard(
            context,
            g: item.value,
            originalIndex: item.key,
            isCompleted: false,
            animationIndex: animationIndex,
          ),
        );
        animationIndex += 1;
        children.add(const SizedBox(height: 8));
      }
    }

    if (completedGoals.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'Completed Goals',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );

      for (final MapEntry<int, SavingsGoal> item in completedGoals) {
        children.add(
          _buildGoalCard(
            context,
            g: item.value,
            originalIndex: item.key,
            isCompleted: true,
            animationIndex: animationIndex,
          ),
        );
        animationIndex += 1;
        children.add(const SizedBox(height: 8));
      }
    }

    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}
