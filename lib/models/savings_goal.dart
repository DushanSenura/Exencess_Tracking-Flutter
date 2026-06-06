class SavingsGoal {
  SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    final double raw = currentAmount / targetAmount;
    return raw.clamp(0, 1);
  }
}
