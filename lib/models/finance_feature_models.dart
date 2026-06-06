import 'transaction_entry.dart';

enum BudgetPeriod { daily, weekly, monthly }

enum AccountType { bank, cash, wallet, creditCard }

enum GoalType { emergencyFund, vacation, education, retirement, custom }

enum TrendWindow { week, month, quarter, year }

enum ThemePack { ocean, sunrise, forest }

enum DashboardLayout { compact, detailed }

enum AppThemePreset { teal, ocean, sunset, forest }

enum AppLocaleOption { en, si, ta }

enum DashboardWidgetId {
  currentBalance,
  incomeExpense,
  netWorthForecast,
  budgetHealth,
  gamification,
  personalizedTips,
  weeklyTrend,
  topCategories,
}

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.amount,
    required this.renewalDate,
    this.active = true,
    this.notes,
    this.lastReminderAt,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime renewalDate;
  bool active;
  final String? notes;
  DateTime? lastReminderAt;

  int daysToRenewal(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime renewal = DateTime(
      renewalDate.year,
      renewalDate.month,
      renewalDate.day,
    );
    return renewal.difference(today).inDays;
  }

  bool isDueSoon(DateTime now, {int withinDays = 3}) {
    if (!active) {
      return false;
    }
    final int days = daysToRenewal(now);
    return days >= 0 && days <= withinDays;
  }
}

class FixedDeposit {
  FixedDeposit({
    required this.id,
    required this.bankName,
    required this.principal,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
    required this.reminderDate,
    this.accountNumber,
    this.reminderEnabled = true,
    this.isClosed = false,
    this.notes,
    this.lastReminderAt,
  });

  final String id;
  final String bankName;
  final String? accountNumber;
  final double principal;
  final double interestRate;
  final DateTime startDate;
  final DateTime maturityDate;
  final DateTime reminderDate;
  bool reminderEnabled;
  bool isClosed;
  final String? notes;
  DateTime? lastReminderAt;

  double get expectedInterest {
    final int days = maturityDate.difference(startDate).inDays;
    if (days <= 0) {
      return 0;
    }
    return principal * (interestRate / 100) * (days / 365);
  }

  double get maturityAmount => principal + expectedInterest;

  int daysToMaturity(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime maturity = DateTime(
      maturityDate.year,
      maturityDate.month,
      maturityDate.day,
    );
    return maturity.difference(today).inDays;
  }

  bool isMatured(DateTime now) {
    return !isClosed && daysToMaturity(now) <= 0;
  }

  bool isReminderDue(DateTime now) {
    if (!reminderEnabled || isClosed) {
      return false;
    }
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime reminder = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
    );
    return !reminder.isAfter(today);
  }
}

class BudgetPlan {
  const BudgetPlan({
    required this.category,
    required this.limit,
    required this.period,
  });

  final String category;
  final double limit;
  final BudgetPeriod period;
}

class RecurringTransactionRule {
  RecurringTransactionRule({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.frequencyDays,
    required this.nextRun,
    this.accountId,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final TransactionType type;
  final int frequencyDays;
  DateTime nextRun;
  final String? accountId;
}

class BillReminder {
  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  bool isPaid;

  bool isOverdue(DateTime now) => !isPaid && dueDate.isBefore(now);

  bool isDueSoon(DateTime now, {int withinDays = 3}) {
    if (isPaid) {
      return false;
    }
    final DateTime end = now.add(Duration(days: withinDays));
    return (dueDate.isAfter(now) || _sameDay(dueDate, now)) &&
        (dueDate.isBefore(end) || _sameDay(dueDate, end));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class FinanceAccount {
  FinanceAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.iconCodePoint,
    this.colorValue,
    this.isLiability = false,
  });

  final String id;
  final String name;
  final AccountType type;
  double balance;
  final int? iconCodePoint;
  final int? colorValue;
  final bool isLiability;
}

class CategoryRule {
  const CategoryRule({required this.keyword, required this.category});

  final String keyword;
  final String category;
}

class GoalInsight {
  const GoalInsight({
    required this.goalName,
    required this.monthsToGoal,
    required this.requiredMonthlyContribution,
  });

  final String goalName;
  final int monthsToGoal;
  final double requiredMonthlyContribution;
}

class TransactionAuditLog {
  const TransactionAuditLog({
    required this.timestamp,
    required this.action,
    required this.transactionTitle,
    required this.amount,
  });

  final DateTime timestamp;
  final String action;
  final String transactionTitle;
  final double amount;
}

class ReportFilter {
  const ReportFilter({
    this.startDate,
    this.endDate,
    this.accountId,
    this.tag,
    this.minAmount,
    this.maxAmount,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? accountId;
  final String? tag;
  final double? minAmount;
  final double? maxAmount;
}

class WeeklyReviewCard {
  const WeeklyReviewCard({required this.title, required this.description});

  final String title;
  final String description;
}
