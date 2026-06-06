import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_data.dart';
import '../models/finance_feature_models.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../database/account_database_service.dart';
import '../services/export_service.dart';
import '../database/finance_database_service.dart';
import '../services/notification_service.dart';

class FinanceViewModel extends ChangeNotifier {
  FinanceViewModel({
    NotificationService? notificationService,
    ExportService? exportService,
    AccountDatabaseService? accountDatabaseService,
    FinanceDatabaseService? financeDatabaseService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _accountDatabaseService = _resolveAccountDatabaseService(
         accountDatabaseService,
       ),
       _financeDatabaseService = _resolveFinanceDatabaseService(
         financeDatabaseService,
       ),
       _exportService = exportService ?? ExportService();

  static AccountDatabaseService _resolveAccountDatabaseService(
    AccountDatabaseService? service,
  ) {
    return service ?? AccountDatabaseService();
  }

  static FinanceDatabaseService _resolveFinanceDatabaseService(
    FinanceDatabaseService? service,
  ) {
    return service ?? FinanceDatabaseService();
  }

  final NotificationService _notificationService;
  final AccountDatabaseService _accountDatabaseService;
  final FinanceDatabaseService _financeDatabaseService;
  final ExportService _exportService;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _notificationsAvailable = false;

  static const String _budgetKey = 'settings_budget';
  static const String _dateTimeKey = 'settings_datetime';
  static const String _rememberSessionKey = 'auth_remember_session';
  static const String _currencyKey = 'settings_currency';
  static const String _themePackKey = 'settings_theme_pack';
  static const String _layoutKey = 'settings_dashboard_layout';
  static const String _profileImageUrlKey = 'settings_profile_image_url';
  static const String _customCategoriesKey = 'settings_custom_categories';
  static const String _automationEnabledKey = 'settings_automation_enabled';
  static const String _automationPercentKey = 'settings_automation_percent';
  static const String _budgetAlertsEnabledKey =
      'settings_budget_alerts_enabled';
  static const String _themeModeDarkKey = 'settings_theme_mode_dark';
  static const String _themePresetKey = 'settings_theme_preset';
  static const String _localeKey = 'settings_locale';
  static const String _cloudSyncEnabledKey = 'settings_cloud_sync_enabled';
  static const String _cloudSyncEmailKey = 'settings_cloud_sync_email';
  static const String _budgetHealthGoalNameKey =
      'settings_budget_health_goal_name';
  static const String _includeLiabilitiesInBalanceKey =
      'settings_include_liabilities_balance';
  static const String _lockEnabledKey = 'security_lock_enabled';
  static const String _biometricEnabledKey = 'security_biometric_enabled';
  static const String _lockPinKey = 'security_pin';
  static const String _lastMoneyActionReminderKey =
      'settings_last_money_action_reminder';

  int selectedIndex = 0;
  bool reminderEnabled = false;
  double monthlyBudget = 4000;
  String userName = '';
  String userEmail = '';
  String userProfileImageUrl = '';
  String _password = '';
  DateTime appDateTime = DateTime.now();
  bool rememberSession = false;

  String selectedCurrency = 'USD';
  ThemePack selectedThemePack = ThemePack.ocean;
  DashboardLayout dashboardLayout = DashboardLayout.detailed;
  bool appLockEnabled = false;
  bool biometricEnabled = false;
  bool includeLiabilitiesInCurrentBalance = false;
  bool savingsAutomationEnabled = false;
  double savingsAutomationPercent = 10;
  bool budgetAlertsEnabled = true;
  bool darkModeEnabled = false;
  AppThemePreset themePreset = AppThemePreset.teal;
  AppLocaleOption localeOption = AppLocaleOption.en;
  bool cloudSyncEnabled = false;
  String cloudSyncEmail = '';
  String? budgetHealthGoalName;
  String? _appPin;
  DateTime? lastBackupAt;
  DateTime? _lastMoneyActionReminderAt;

  final List<TransactionEntry> transactions = <TransactionEntry>[];
  final List<SavingsGoal> goals = <SavingsGoal>[];
  final Map<String, double> categoryBudgets = <String, double>{};
  final Map<String, double> dailyCategoryBudgets = <String, double>{};
  final Map<String, double> weeklyCategoryBudgets = <String, double>{};
  final List<FinanceAccount> accounts = <FinanceAccount>[];
  final List<RecurringTransactionRule> recurringRules =
      <RecurringTransactionRule>[];
  final List<BillReminder> billReminders = <BillReminder>[];
  final List<FixedDeposit> fixedDeposits = <FixedDeposit>[];
  final List<SubscriptionPlan> subscriptions = <SubscriptionPlan>[];
  final List<CategoryRule> categoryRules = <CategoryRule>[];
  final List<TransactionAuditLog> auditLogs = <TransactionAuditLog>[];
  final Set<String> customCategories = <String>{
    'Food',
    'Transport',
    'Utilities',
    'Shopping',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
  };
  final Set<String> customTags = <String>{'Essential', 'Recurring', 'Family'};
  final List<DashboardWidgetId> dashboardWidgetOrder = <DashboardWidgetId>[
    DashboardWidgetId.currentBalance,
    DashboardWidgetId.incomeExpense,
    DashboardWidgetId.netWorthForecast,
    DashboardWidgetId.budgetHealth,
    DashboardWidgetId.gamification,
    DashboardWidgetId.personalizedTips,
    DashboardWidgetId.weeklyTrend,
    DashboardWidgetId.topCategories,
  ];
  final Set<DashboardWidgetId> hiddenDashboardWidgets = <DashboardWidgetId>{};

  final Map<String, double> exchangeRates = <String, double>{
    'USD': 1,
    'EUR': 0.92,
    'INR': 83.0,
    'LKR': 300.0,
    'GBP': 0.78,
    'JPY': 149.0,
  };

  final List<String> monthlyChallenges = <String>[
    'No-spend weekend',
    'Reduce dining out by 15%',
    'Save 10% of income',
  ];

  Future<void> initialize() async {
    try {
      await _accountDatabaseService.initialize();
      await _loadAccountData();
    } catch (_) {
      // Keep defaults when DB cannot be initialized on current runtime.
    }

    try {
      await _financeDatabaseService.initialize();
      await _loadFinanceData();
    } catch (_) {
      // Keep defaults when finance DB cannot be initialized.
    }

    try {
      _notificationsAvailable = await _notificationService.initialize();
    } on MissingPluginException {
      _notificationsAvailable = false;
    }

    try {
      await _loadSettings();
      _hydrateAccountBalancesFromTransactions();
      applyRecurringTransactionsForDate(appDateTime, notify: false);
      unawaited(checkFixedDepositReminders());
      unawaited(checkSubscriptionAndBudgetReminders());
    } on MissingPluginException {
      // Keep defaults if local storage plugin is unavailable.
    }

    notifyListeners();
  }

  Future<void> _loadAccountData() async {
    final AccountData? account = await _accountDatabaseService.getAccount();
    if (account == null) {
      await _accountDatabaseService.upsertAccount(
        AccountData(name: userName, email: userEmail, password: _password),
      );
      return;
    }

    userName = account.name;
    userEmail = account.email;
    _password = account.password;
  }

  Future<void> _persistAccountData() async {
    await _accountDatabaseService.upsertAccount(
      AccountData(name: userName, email: userEmail, password: _password),
    );
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('settings_name');
    await prefs.remove('settings_email');
    await prefs.remove('settings_password');

    monthlyBudget = prefs.getDouble(_budgetKey) ?? monthlyBudget;
    rememberSession = prefs.getBool(_rememberSessionKey) ?? false;
    selectedCurrency = prefs.getString(_currencyKey) ?? selectedCurrency;
    userProfileImageUrl =
        prefs.getString(_profileImageUrlKey) ?? userProfileImageUrl;
    savingsAutomationEnabled =
        prefs.getBool(_automationEnabledKey) ?? savingsAutomationEnabled;
    savingsAutomationPercent =
        prefs.getDouble(_automationPercentKey) ?? savingsAutomationPercent;
    budgetAlertsEnabled =
        prefs.getBool(_budgetAlertsEnabledKey) ?? budgetAlertsEnabled;
    darkModeEnabled = prefs.getBool(_themeModeDarkKey) ?? darkModeEnabled;
    cloudSyncEnabled = prefs.getBool(_cloudSyncEnabledKey) ?? cloudSyncEnabled;
    cloudSyncEmail = prefs.getString(_cloudSyncEmailKey) ?? cloudSyncEmail;
    appLockEnabled = prefs.getBool(_lockEnabledKey) ?? appLockEnabled;
    biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? biometricEnabled;
    includeLiabilitiesInCurrentBalance =
        prefs.getBool(_includeLiabilitiesInBalanceKey) ??
        includeLiabilitiesInCurrentBalance;
    final String? storedPin = prefs.getString(_lockPinKey);
    _appPin = storedPin == null ? null : _deobfuscate(storedPin);
    final String? lastMoneyActionReminderIso = prefs.getString(
      _lastMoneyActionReminderKey,
    );
    _lastMoneyActionReminderAt = lastMoneyActionReminderIso == null
        ? null
        : DateTime.tryParse(lastMoneyActionReminderIso);

    final String? themeString = prefs.getString(_themePackKey);
    if (themeString != null) {
      selectedThemePack = ThemePack.values.firstWhere(
        (ThemePack value) => value.name == themeString,
        orElse: () => selectedThemePack,
      );
    }

    final String? presetString = prefs.getString(_themePresetKey);
    if (presetString != null) {
      themePreset = AppThemePreset.values.firstWhere(
        (AppThemePreset value) => value.name == presetString,
        orElse: () => themePreset,
      );
    }

    final String? localeString = prefs.getString(_localeKey);
    if (localeString != null) {
      localeOption = AppLocaleOption.values.firstWhere(
        (AppLocaleOption value) => value.name == localeString,
        orElse: () => localeOption,
      );
    }

    final String? layoutString = prefs.getString(_layoutKey);
    if (layoutString != null) {
      dashboardLayout = DashboardLayout.values.firstWhere(
        (DashboardLayout value) => value.name == layoutString,
        orElse: () => dashboardLayout,
      );
    }

    final String? dateTimeIso = prefs.getString(_dateTimeKey);
    if (dateTimeIso != null) {
      appDateTime = DateTime.tryParse(dateTimeIso) ?? appDateTime;
    }

    final String? savedBudgetHealthGoalName = prefs.getString(
      _budgetHealthGoalNameKey,
    );
    if (savedBudgetHealthGoalName != null &&
        savedBudgetHealthGoalName.trim().isNotEmpty) {
      budgetHealthGoalName = savedBudgetHealthGoalName;
    }

    final List<String>? savedCategories = prefs.getStringList(
      _customCategoriesKey,
    );
    if (savedCategories != null && savedCategories.isNotEmpty) {
      customCategories
        ..clear()
        ..addAll(savedCategories.map((String item) => item.trim()))
        ..removeWhere((String item) => item.isEmpty);
    }
  }

  Future<void> _persistSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, monthlyBudget);
    await prefs.setString(_dateTimeKey, appDateTime.toIso8601String());
    await prefs.setString(_currencyKey, selectedCurrency);
    await prefs.setString(_profileImageUrlKey, userProfileImageUrl);
    await prefs.setBool(_automationEnabledKey, savingsAutomationEnabled);
    await prefs.setDouble(_automationPercentKey, savingsAutomationPercent);
    await prefs.setBool(_budgetAlertsEnabledKey, budgetAlertsEnabled);
    await prefs.setBool(_themeModeDarkKey, darkModeEnabled);
    await prefs.setString(_themePresetKey, themePreset.name);
    await prefs.setString(_localeKey, localeOption.name);
    await prefs.setBool(_cloudSyncEnabledKey, cloudSyncEnabled);
    await prefs.setString(_cloudSyncEmailKey, cloudSyncEmail);
    if (budgetHealthGoalName != null &&
        budgetHealthGoalName!.trim().isNotEmpty) {
      await prefs.setString(_budgetHealthGoalNameKey, budgetHealthGoalName!);
    } else {
      await prefs.remove(_budgetHealthGoalNameKey);
    }
    await prefs.setString(_themePackKey, selectedThemePack.name);
    await prefs.setString(_layoutKey, dashboardLayout.name);
    await prefs.setStringList(
      _customCategoriesKey,
      customCategories.toList()..sort(),
    );
    await prefs.setBool(
      _includeLiabilitiesInBalanceKey,
      includeLiabilitiesInCurrentBalance,
    );
    await prefs.setBool(_lockEnabledKey, appLockEnabled);
    await prefs.setBool(_biometricEnabledKey, biometricEnabled);
    if (_appPin != null) {
      await prefs.setString(_lockPinKey, _obfuscate(_appPin!));
    }
    if (_lastMoneyActionReminderAt != null) {
      await prefs.setString(
        _lastMoneyActionReminderKey,
        _lastMoneyActionReminderAt!.toIso8601String(),
      );
    } else {
      await prefs.remove(_lastMoneyActionReminderKey);
    }
  }

  Future<void> _persistRememberSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberSessionKey, rememberSession);
  }

  Future<void> _persistFinanceData() async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'transactions': transactions
          .map(
            (TransactionEntry tx) => <String, dynamic>{
              'id': tx.id,
              'title': tx.title,
              'category': tx.category,
              'amount': tx.amount,
              'date': tx.date.toIso8601String(),
              'type': tx.type.name,
              'accountId': tx.accountId,
              'merchant': tx.merchant,
              'tags': tx.tags,
              'updatedAt': tx.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'goals': goals
          .map(
            (SavingsGoal goal) => <String, dynamic>{
              'name': goal.name,
              'targetAmount': goal.targetAmount,
              'currentAmount': goal.currentAmount,
              'deadline': goal.deadline.toIso8601String(),
            },
          )
          .toList(),
      'accounts': accounts
          .map(
            (FinanceAccount account) => <String, dynamic>{
              'id': account.id,
              'name': account.name,
              'type': account.type.name,
              'balance': account.balance,
              'iconCodePoint': account.iconCodePoint,
              'colorValue': account.colorValue,
              'isLiability': account.isLiability,
            },
          )
          .toList(),
      'categoryBudgets': categoryBudgets,
      'dailyCategoryBudgets': dailyCategoryBudgets,
      'weeklyCategoryBudgets': weeklyCategoryBudgets,
      'customCategories': customCategories.toList(),
      'subscriptions': subscriptions
          .map(
            (SubscriptionPlan sub) => <String, dynamic>{
              'id': sub.id,
              'name': sub.name,
              'amount': sub.amount,
              'renewalDate': sub.renewalDate.toIso8601String(),
              'active': sub.active,
              'notes': sub.notes,
              'lastReminderAt': sub.lastReminderAt?.toIso8601String(),
            },
          )
          .toList(),
      'fixedDeposits': fixedDeposits
          .map(
            (FixedDeposit fd) => <String, dynamic>{
              'id': fd.id,
              'bankName': fd.bankName,
              'accountNumber': fd.accountNumber,
              'principal': fd.principal,
              'interestRate': fd.interestRate,
              'startDate': fd.startDate.toIso8601String(),
              'maturityDate': fd.maturityDate.toIso8601String(),
              'reminderDate': fd.reminderDate.toIso8601String(),
              'reminderEnabled': fd.reminderEnabled,
              'isClosed': fd.isClosed,
              'notes': fd.notes,
              'lastReminderAt': fd.lastReminderAt?.toIso8601String(),
            },
          )
          .toList(),
      'dashboardWidgetOrder': dashboardWidgetOrder
          .map((DashboardWidgetId id) => id.name)
          .toList(),
      'hiddenDashboardWidgets': hiddenDashboardWidgets
          .map((DashboardWidgetId id) => id.name)
          .toList(),
    };
    await _financeDatabaseService.saveState(jsonEncode(payload));
  }

  Future<void> _loadFinanceData() async {
    final String? raw = await _financeDatabaseService.loadState();
    if (raw == null || raw.isEmpty) {
      return;
    }

    final Map<String, dynamic> payload =
        jsonDecode(raw) as Map<String, dynamic>;

    final List<dynamic> txRows =
        payload['transactions'] as List<dynamic>? ?? <dynamic>[];
    if (txRows.isNotEmpty) {
      transactions
        ..clear()
        ..addAll(
          txRows.map((dynamic item) {
            final Map<String, dynamic> tx = item as Map<String, dynamic>;
            return TransactionEntry(
              id: (tx['id'] ?? '').toString(),
              title: (tx['title'] ?? 'Transaction').toString(),
              category: (tx['category'] ?? 'Uncategorized').toString(),
              amount: (tx['amount'] as num?)?.toDouble() ?? 0,
              date:
                  DateTime.tryParse((tx['date'] ?? '').toString()) ??
                  DateTime.now(),
              type: (tx['type'] ?? 'expense') == 'income'
                  ? TransactionType.income
                  : TransactionType.expense,
              accountId: tx['accountId']?.toString(),
              merchant: tx['merchant']?.toString(),
              tags: (tx['tags'] as List<dynamic>? ?? <dynamic>[])
                  .map((dynamic v) => v.toString())
                  .toList(),
              updatedAt:
                  DateTime.tryParse((tx['updatedAt'] ?? '').toString()) ??
                  DateTime.now(),
            );
          }),
        );
    }

    final List<dynamic> goalRows =
        payload['goals'] as List<dynamic>? ?? <dynamic>[];
    if (goalRows.isNotEmpty) {
      goals
        ..clear()
        ..addAll(
          goalRows.map((dynamic item) {
            final Map<String, dynamic> goal = item as Map<String, dynamic>;
            return SavingsGoal(
              name: (goal['name'] ?? 'Goal').toString(),
              targetAmount: (goal['targetAmount'] as num?)?.toDouble() ?? 0,
              currentAmount: (goal['currentAmount'] as num?)?.toDouble() ?? 0,
              deadline:
                  DateTime.tryParse((goal['deadline'] ?? '').toString()) ??
                  DateTime.now(),
            );
          }),
        );
    }

    final List<dynamic> accountRows =
        payload['accounts'] as List<dynamic>? ?? <dynamic>[];
    if (accountRows.isNotEmpty) {
      accounts
        ..clear()
        ..addAll(
          accountRows.map((dynamic item) {
            final Map<String, dynamic> account = item as Map<String, dynamic>;
            final String typeName = (account['type'] ?? 'wallet').toString();
            final AccountType type = AccountType.values.firstWhere(
              (AccountType t) => t.name == typeName,
              orElse: () => AccountType.wallet,
            );
            return FinanceAccount(
              id: (account['id'] ?? '').toString(),
              name: (account['name'] ?? 'Account').toString(),
              type: type,
              balance: (account['balance'] as num?)?.toDouble() ?? 0,
              iconCodePoint: account['iconCodePoint'] as int?,
              colorValue: account['colorValue'] as int?,
              isLiability: account['isLiability'] == true,
            );
          }),
        );
    }

    void loadBudgetMap(String key, Map<String, double> target) {
      final Map<String, dynamic>? map = payload[key] as Map<String, dynamic>?;
      if (map == null) {
        return;
      }
      target
        ..clear()
        ..addAll(
          map.map(
            (String k, dynamic v) =>
                MapEntry<String, double>(k, (v as num).toDouble()),
          ),
        );
    }

    loadBudgetMap('categoryBudgets', categoryBudgets);
    loadBudgetMap('dailyCategoryBudgets', dailyCategoryBudgets);
    loadBudgetMap('weeklyCategoryBudgets', weeklyCategoryBudgets);

    final List<dynamic>? categoryRows =
        payload['customCategories'] as List<dynamic>?;
    if (categoryRows != null && categoryRows.isNotEmpty) {
      customCategories
        ..clear()
        ..addAll(categoryRows.map((dynamic v) => v.toString()));
    }

    final List<dynamic> subRows =
        payload['subscriptions'] as List<dynamic>? ?? <dynamic>[];
    if (subRows.isNotEmpty) {
      subscriptions
        ..clear()
        ..addAll(
          subRows.map((dynamic item) {
            final Map<String, dynamic> sub = item as Map<String, dynamic>;
            return SubscriptionPlan(
              id: (sub['id'] ?? '').toString(),
              name: (sub['name'] ?? 'Subscription').toString(),
              amount: (sub['amount'] as num?)?.toDouble() ?? 0,
              renewalDate:
                  DateTime.tryParse((sub['renewalDate'] ?? '').toString()) ??
                  DateTime.now(),
              active: sub['active'] != false,
              notes: sub['notes']?.toString(),
              lastReminderAt: DateTime.tryParse(
                (sub['lastReminderAt'] ?? '').toString(),
              ),
            );
          }),
        );
    }

    final List<dynamic> fdRows =
        payload['fixedDeposits'] as List<dynamic>? ?? <dynamic>[];
    if (fdRows.isNotEmpty) {
      fixedDeposits
        ..clear()
        ..addAll(
          fdRows.map((dynamic item) {
            final Map<String, dynamic> fd = item as Map<String, dynamic>;
            final DateTime startDate =
                DateTime.tryParse((fd['startDate'] ?? '').toString()) ??
                DateTime.now();
            final DateTime maturityDate =
                DateTime.tryParse((fd['maturityDate'] ?? '').toString()) ??
                startDate.add(const Duration(days: 365));
            return FixedDeposit(
              id: (fd['id'] ?? '').toString(),
              bankName: (fd['bankName'] ?? 'Fixed Deposit').toString(),
              accountNumber: fd['accountNumber']?.toString(),
              principal: (fd['principal'] as num?)?.toDouble() ?? 0,
              interestRate: (fd['interestRate'] as num?)?.toDouble() ?? 0,
              startDate: startDate,
              maturityDate: maturityDate,
              reminderDate:
                  DateTime.tryParse((fd['reminderDate'] ?? '').toString()) ??
                  maturityDate.subtract(const Duration(days: 7)),
              reminderEnabled: fd['reminderEnabled'] != false,
              isClosed: fd['isClosed'] == true,
              notes: fd['notes']?.toString(),
              lastReminderAt: DateTime.tryParse(
                (fd['lastReminderAt'] ?? '').toString(),
              ),
            );
          }),
        );
    }

    final List<dynamic>? widgetOrderRows =
        payload['dashboardWidgetOrder'] as List<dynamic>?;
    if (widgetOrderRows != null && widgetOrderRows.isNotEmpty) {
      dashboardWidgetOrder
        ..clear()
        ..addAll(
          widgetOrderRows.map((dynamic value) {
            final String name = value.toString();
            return DashboardWidgetId.values.firstWhere(
              (DashboardWidgetId id) => id.name == name,
              orElse: () => DashboardWidgetId.currentBalance,
            );
          }),
        );
    }

    final List<dynamic>? hiddenRows =
        payload['hiddenDashboardWidgets'] as List<dynamic>?;
    if (hiddenRows != null) {
      hiddenDashboardWidgets
        ..clear()
        ..addAll(
          hiddenRows.map((dynamic value) {
            final String name = value.toString();
            return DashboardWidgetId.values.firstWhere(
              (DashboardWidgetId id) => id.name == name,
              orElse: () => DashboardWidgetId.currentBalance,
            );
          }),
        );
    }
  }

  void _queueFinancePersist() {
    unawaited(_persistFinanceData());
  }

  void _hydrateAccountBalancesFromTransactions() {
    final Map<String, double> balances = <String, double>{
      for (final FinanceAccount account in accounts)
        account.id: account.balance,
    };

    for (final TransactionEntry tx in transactions) {
      if (tx.accountId == null || !balances.containsKey(tx.accountId)) {
        continue;
      }
      final double signed = tx.type == TransactionType.expense
          ? -tx.amount
          : tx.amount;
      balances[tx.accountId!] = (balances[tx.accountId!] ?? 0) + signed;
    }

    for (final FinanceAccount account in accounts) {
      account.balance = balances[account.id] ?? account.balance;
    }
  }

  String get currencySymbol {
    switch (selectedCurrency) {
      case 'EUR':
        return 'EUR ';
      case 'INR':
        return 'INR ';
      case 'LKR':
        return 'LKR ';
      case 'GBP':
        return 'GBP ';
      case 'JPY':
        return 'JPY ';
      case 'USD':
        return r'$';
      default:
        return '$selectedCurrency ';
    }
  }

  Color get themeSeedColor {
    switch (themePreset) {
      case AppThemePreset.teal:
        return const Color(0xFF0F766E);
      case AppThemePreset.ocean:
        return const Color(0xFF1E429F);
      case AppThemePreset.sunset:
        return const Color(0xFFC05621);
      case AppThemePreset.forest:
        return const Color(0xFF166534);
    }
  }

  String get localeCode => localeOption.name;

  double convertAmount(double amount, {String? toCurrency}) {
    final String target = toCurrency ?? selectedCurrency;
    final double base = exchangeRates['USD'] ?? 1;
    final double to = exchangeRates[target] ?? base;
    if (to == 0) {
      return amount;
    }
    return amount * (to / base);
  }

  void setRememberSession(bool value) {
    rememberSession = value;
    _persistRememberSession();
  }

  void clearRememberSession() {
    rememberSession = false;
    _persistRememberSession();
  }

  void setCurrency(String currencyCode) {
    if (!exchangeRates.containsKey(currencyCode)) {
      return;
    }
    selectedCurrency = currencyCode;
    _persistSettings();
    notifyListeners();
  }

  void updateExchangeRate(String code, double value) {
    if (value <= 0) {
      return;
    }
    exchangeRates[code] = value;
    notifyListeners();
  }

  void setSavingsAutomation({required bool enabled, required double percent}) {
    savingsAutomationEnabled = enabled;
    savingsAutomationPercent = percent.clamp(0, 100);
    _persistSettings();
    notifyListeners();
  }

  double _applySavingsAutomation(TransactionEntry tx) {
    if (!savingsAutomationEnabled || tx.type != TransactionType.income) {
      return 0;
    }
    if (goals.isEmpty || savingsAutomationPercent <= 0) {
      return 0;
    }
    final double amount = tx.amount * (savingsAutomationPercent / 100);
    if (amount <= 0) {
      return 0;
    }
    final SavingsGoal first = goals.first;
    final double next = first.currentAmount + amount;
    goals[0] = SavingsGoal(
      name: first.name,
      targetAmount: first.targetAmount,
      currentAmount: next,
      deadline: first.deadline,
    );
    return amount;
  }

  List<String> budgetAlerts() {
    if (!budgetAlertsEnabled) {
      return <String>[];
    }
    final List<String> alerts = <String>[];
    final double monthlyUsage = budgetUsage;
    if (monthlyUsage >= 1) {
      alerts.add('Monthly budget exceeded.');
    } else if (monthlyUsage >= 0.9) {
      alerts.add('Monthly budget reached 90%.');
    } else if (monthlyUsage >= 0.7) {
      alerts.add('Monthly budget reached 70%.');
    }

    void checkCategory(
      String label,
      Map<String, double> spent,
      Map<String, double> budget,
    ) {
      for (final MapEntry<String, double> entry in budget.entries) {
        final double cap = entry.value;
        if (cap <= 0) {
          continue;
        }
        final double usage = (spent[entry.key] ?? 0) / cap;
        if (usage >= 1) {
          alerts.add('$label ${entry.key} exceeded.');
        } else if (usage >= 0.9) {
          alerts.add('$label ${entry.key} reached 90%.');
        } else if (usage >= 0.7) {
          alerts.add('$label ${entry.key} reached 70%.');
        }
      }
    }

    checkCategory('Daily', dailyExpenseByCategory, dailyCategoryBudgets);
    checkCategory('Weekly', weeklyExpenseByCategory, weeklyCategoryBudgets);
    checkCategory('Monthly', expenseByCategory, categoryBudgets);
    return alerts;
  }

  double get monthlyBudgetRemaining {
    return math.max(0, monthlyBudget - totalExpense);
  }

  List<String> budgetActionReminders() {
    if (!budgetAlertsEnabled) {
      return <String>[];
    }

    final List<String> reminders = <String>[];
    final double usage = budgetUsage;
    final double upcomingSubscriptions = dueSoonSubscriptions.fold(
      0.0,
      (double sum, SubscriptionPlan sub) => sum + sub.amount,
    );

    if (upcomingSubscriptions > 0) {
      reminders.add(
        'Keep $currencySymbol${upcomingSubscriptions.toStringAsFixed(0)} ready for upcoming subscriptions.',
      );
    }

    if (usage >= 1) {
      reminders.add(
        'Budget is over limit. Pay essentials only and pause non-essential spending.',
      );
    } else if (usage >= 0.9) {
      reminders.add(
        'Budget is almost used. Save remaining cash and avoid optional purchases.',
      );
    } else if (usage <= 0.6 && balance > 0) {
      final double saveAmount = math.min(
        balance * 0.1,
        math.max(0, monthlyBudgetRemaining * 0.5),
      );
      if (saveAmount > 0) {
        reminders.add(
          'You can save about $currencySymbol${saveAmount.toStringAsFixed(0)} this month.',
        );
      }
    }

    if (endOfMonthForecastBalance < upcomingSubscriptions &&
        upcomingSubscriptions > 0) {
      reminders.add(
        'Forecast is tight. Add income or reduce spending before subscriptions renew.',
      );
    }

    return reminders;
  }

  void setBudgetAlertsEnabled(bool value) {
    budgetAlertsEnabled = value;
    _persistSettings();
    notifyListeners();
  }

  void setDarkModeEnabled(bool enabled) {
    darkModeEnabled = enabled;
    _persistSettings();
    notifyListeners();
  }

  void setThemePreset(AppThemePreset preset) {
    themePreset = preset;
    _persistSettings();
    notifyListeners();
  }

  void setLocaleOption(AppLocaleOption option) {
    localeOption = option;
    _persistSettings();
    notifyListeners();
  }

  void setCloudSync({required bool enabled, String? email}) {
    cloudSyncEnabled = enabled;
    if (email != null && email.trim().isNotEmpty) {
      cloudSyncEmail = email.trim();
    }
    _persistSettings();
    notifyListeners();
  }

  Future<String> backupToCloudByEmail() async {
    if (!cloudSyncEnabled || cloudSyncEmail.isEmpty) {
      return 'Enable cloud sync and set your email first.';
    }
    final String key = cloudSyncEmail.toLowerCase();
    final String payload = generateEncryptedBackupPayload();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_backup_$key', payload);
    await prefs.setString(
      'cloud_backup_at_$key',
      DateTime.now().toIso8601String(),
    );
    return 'Backup stored for $cloudSyncEmail (cloud sync hook).';
  }

  Future<String> restoreFromCloudByEmail() async {
    if (!cloudSyncEnabled || cloudSyncEmail.isEmpty) {
      return 'Enable cloud sync and set your email first.';
    }
    final String key = cloudSyncEmail.toLowerCase();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String backup = prefs.getString('cloud_backup_$key') ?? '';
    if (backup.isEmpty) {
      return 'No cloud backup payload found.';
    }
    return importEncryptedBackupPayload(backup);
  }

  Future<String> autoSyncOnLoginEmail(String email) async {
    final String clean = email.trim().toLowerCase();
    if (clean.isEmpty) {
      return 'No login email for auto-sync.';
    }
    setCloudSync(enabled: true, email: clean);
    final String restoreMessage = await restoreFromCloudByEmail();
    final String backupMessage = await backupToCloudByEmail();
    return '$restoreMessage | $backupMessage';
  }

  void addSubscription({
    required String name,
    required double amount,
    required DateTime renewalDate,
    String? notes,
  }) {
    subscriptions.add(
      SubscriptionPlan(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        amount: amount,
        renewalDate: renewalDate,
        notes: notes?.trim(),
      ),
    );
    _queueFinancePersist();
    notifyListeners();
    unawaited(checkSubscriptionAndBudgetReminders());
  }

  void toggleSubscriptionActive(String id, bool active) {
    final int index = subscriptions.indexWhere(
      (SubscriptionPlan s) => s.id == id,
    );
    if (index < 0) {
      return;
    }
    subscriptions[index].active = active;
    _queueFinancePersist();
    notifyListeners();
    unawaited(checkSubscriptionAndBudgetReminders());
  }

  void removeSubscription(String id) {
    subscriptions.removeWhere((SubscriptionPlan s) => s.id == id);
    _queueFinancePersist();
    notifyListeners();
    unawaited(checkSubscriptionAndBudgetReminders());
  }

  List<SubscriptionPlan> get dueSoonSubscriptions {
    return subscriptions
        .where((SubscriptionPlan sub) => sub.isDueSoon(appDateTime))
        .toList()
      ..sort(
        (SubscriptionPlan a, SubscriptionPlan b) =>
            a.renewalDate.compareTo(b.renewalDate),
      );
  }

  List<String> get subscriptionAlerts {
    return dueSoonSubscriptions.map((SubscriptionPlan sub) {
      final int days = sub.daysToRenewal(appDateTime);
      final String dueText = days <= 0
          ? 'due today'
          : days == 1
          ? 'due tomorrow'
          : 'due in $days days';
      return '${sub.name} is $dueText (${currencySymbol}${sub.amount.toStringAsFixed(0)}).';
    }).toList();
  }

  Future<void> checkSubscriptionAndBudgetReminders() async {
    if (!_notificationsAvailable || !reminderEnabled) {
      return;
    }

    bool changed = false;
    for (final SubscriptionPlan sub in dueSoonSubscriptions) {
      final DateTime? last = sub.lastReminderAt;
      final bool alreadySentToday =
          last != null &&
          last.year == appDateTime.year &&
          last.month == appDateTime.month &&
          last.day == appDateTime.day;
      if (alreadySentToday) {
        continue;
      }

      final int days = sub.daysToRenewal(appDateTime);
      final String body = days <= 0
          ? 'Pay ${sub.name} today: $currencySymbol${sub.amount.toStringAsFixed(0)}.'
          : 'Prepare $currencySymbol${sub.amount.toStringAsFixed(0)} for ${sub.name}, due in $days day(s).';
      final bool sent = await _notificationService.showSubscriptionReminder(
        id: sub.id.hashCode.abs() % 100000,
        title: 'Subscription payment reminder',
        body: body,
      );
      if (sent) {
        sub.lastReminderAt = appDateTime;
        changed = true;
      }
    }

    final DateTime? lastBudgetReminder = _lastMoneyActionReminderAt;
    final bool budgetSentToday =
        lastBudgetReminder != null &&
        lastBudgetReminder.year == appDateTime.year &&
        lastBudgetReminder.month == appDateTime.month &&
        lastBudgetReminder.day == appDateTime.day;
    final List<String> moneyActions = budgetActionReminders();
    if (!budgetSentToday && moneyActions.isNotEmpty) {
      final bool sent = await _notificationService.showMoneyActionReminder(
        id: 4001,
        title: 'Budget action reminder',
        body: moneyActions.first,
      );
      if (sent) {
        _lastMoneyActionReminderAt = appDateTime;
        unawaited(_persistSettings());
      }
    }

    if (changed) {
      _queueFinancePersist();
      notifyListeners();
    }
  }

  double get fixedDepositPrincipal {
    return fixedDeposits
        .where((FixedDeposit fd) => !fd.isClosed)
        .fold(0.0, (double sum, FixedDeposit fd) => sum + fd.principal);
  }

  double get fixedDepositExpectedInterest {
    return fixedDeposits
        .where((FixedDeposit fd) => !fd.isClosed)
        .fold(0.0, (double sum, FixedDeposit fd) => sum + fd.expectedInterest);
  }

  List<FixedDeposit> get maturedFixedDeposits {
    return fixedDeposits
        .where((FixedDeposit fd) => fd.isMatured(appDateTime))
        .toList();
  }

  List<FixedDeposit> get dueSoonFixedDeposits {
    return fixedDeposits.where((FixedDeposit fd) {
      if (fd.isClosed || fd.isMatured(appDateTime)) {
        return false;
      }
      final int days = fd.daysToMaturity(appDateTime);
      return days >= 0 && days <= 30;
    }).toList();
  }

  String addFixedDeposit({
    required String bankName,
    String? accountNumber,
    required double principal,
    required double interestRate,
    required DateTime startDate,
    required DateTime maturityDate,
    required DateTime reminderDate,
    bool reminderEnabled = true,
    String? notes,
  }) {
    final String cleanBank = bankName.trim();
    if (cleanBank.isEmpty) {
      return 'Bank name is required.';
    }
    if (principal <= 0) {
      return 'Principal must be greater than zero.';
    }
    if (interestRate < 0) {
      return 'Interest rate cannot be negative.';
    }
    if (!maturityDate.isAfter(startDate)) {
      return 'Maturity date must be after start date.';
    }

    fixedDeposits.add(
      FixedDeposit(
        id: 'fd_${DateTime.now().millisecondsSinceEpoch}',
        bankName: cleanBank,
        accountNumber: accountNumber?.trim(),
        principal: principal,
        interestRate: interestRate,
        startDate: startDate,
        maturityDate: maturityDate,
        reminderDate: reminderDate.isAfter(maturityDate)
            ? maturityDate
            : reminderDate,
        reminderEnabled: reminderEnabled,
        notes: notes?.trim(),
      ),
    );
    _queueFinancePersist();
    notifyListeners();
    unawaited(checkFixedDepositReminders());
    return 'Fixed deposit added.';
  }

  void toggleFixedDepositReminder(String id, bool enabled) {
    final FixedDeposit? fd = _findFixedDeposit(id);
    if (fd == null) {
      return;
    }
    fd.reminderEnabled = enabled;
    _queueFinancePersist();
    notifyListeners();
  }

  String closeFixedDeposit(String id) {
    final FixedDeposit? fd = _findFixedDeposit(id);
    if (fd == null) {
      return 'Fixed deposit not found.';
    }
    fd.isClosed = true;
    _queueFinancePersist();
    notifyListeners();
    return 'Fixed deposit closed.';
  }

  String removeFixedDeposit(String id) {
    final int before = fixedDeposits.length;
    fixedDeposits.removeWhere((FixedDeposit fd) => fd.id == id);
    if (fixedDeposits.length == before) {
      return 'Fixed deposit not found.';
    }
    _queueFinancePersist();
    notifyListeners();
    return 'Fixed deposit deleted.';
  }

  FixedDeposit? _findFixedDeposit(String id) {
    for (final FixedDeposit fd in fixedDeposits) {
      if (fd.id == id) {
        return fd;
      }
    }
    return null;
  }

  Future<void> checkFixedDepositReminders() async {
    if (!_notificationsAvailable) {
      return;
    }

    bool changed = false;
    for (final FixedDeposit fd in fixedDeposits) {
      if (!fd.isReminderDue(appDateTime)) {
        continue;
      }
      final DateTime? last = fd.lastReminderAt;
      final bool alreadySentToday =
          last != null &&
          last.year == appDateTime.year &&
          last.month == appDateTime.month &&
          last.day == appDateTime.day;
      if (alreadySentToday) {
        continue;
      }

      final int days = fd.daysToMaturity(appDateTime);
      final String body = days <= 0
          ? '${fd.bankName} FD has matured. Expected value: $currencySymbol${fd.maturityAmount.toStringAsFixed(0)}.'
          : '${fd.bankName} FD matures in $days day(s). Expected value: $currencySymbol${fd.maturityAmount.toStringAsFixed(0)}.';
      final bool sent = await _notificationService.showFixedDepositReminder(
        id: fd.id.hashCode.abs() % 100000,
        title: 'FD maturity reminder',
        body: body,
      );
      if (sent) {
        fd.lastReminderAt = appDateTime;
        changed = true;
      }
    }

    if (changed) {
      _queueFinancePersist();
      notifyListeners();
    }
  }

  void reorderDashboardWidgets(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final DashboardWidgetId item = dashboardWidgetOrder.removeAt(oldIndex);
    dashboardWidgetOrder.insert(newIndex, item);
    _queueFinancePersist();
    notifyListeners();
  }

  void setDashboardWidgetVisible(DashboardWidgetId id, bool visible) {
    if (visible) {
      hiddenDashboardWidgets.remove(id);
    } else {
      hiddenDashboardWidgets.add(id);
    }
    _queueFinancePersist();
    unawaited(checkSubscriptionAndBudgetReminders());
    notifyListeners();
  }

  List<DashboardWidgetId> get visibleDashboardWidgets {
    return dashboardWidgetOrder
        .where((DashboardWidgetId id) => !hiddenDashboardWidgets.contains(id))
        .toList();
  }

  void setThemePack(ThemePack pack) {
    selectedThemePack = pack;
    _persistSettings();
    notifyListeners();
  }

  void setDashboardLayout(DashboardLayout layout) {
    dashboardLayout = layout;
    _persistSettings();
    notifyListeners();
  }

  String setAppLockPin(String pin) {
    final String cleanPin = pin.trim();
    final RegExp pinPattern = RegExp(r'^\d{4}$');
    if (!pinPattern.hasMatch(cleanPin)) {
      return 'PIN must be exactly 4 digits.';
    }
    _appPin = cleanPin;
    appLockEnabled = true;
    _persistSettings();
    notifyListeners();
    return 'App lock enabled.';
  }

  bool validateAppPin(String pin) {
    if (_appPin == null) {
      return false;
    }
    return _appPin == pin || _deobfuscate(_appPin!) == pin;
  }

  void setBiometricEnabled(bool enabled) {
    biometricEnabled = enabled;
    _persistSettings();
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    try {
      final bool isSupported = await _localAuthentication.isDeviceSupported();
      final bool canCheck = await _localAuthentication.canCheckBiometrics;
      final List<BiometricType> available = await _localAuthentication
          .getAvailableBiometrics();
      return isSupported && canCheck && available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access your finance app',
  }) async {
    try {
      final bool canUse = await canUseBiometrics();
      if (!canUse) {
        return false;
      }
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<String> setBiometricEnabledWithValidation(bool enabled) async {
    if (!enabled) {
      biometricEnabled = false;
      await _persistSettings();
      notifyListeners();
      return 'Biometric unlock disabled.';
    }

    final bool canUse = await canUseBiometrics();
    if (!canUse) {
      return 'Biometric authentication is not available on this device.';
    }

    final bool authenticated = await authenticateWithBiometrics(
      reason: 'Confirm to enable biometric unlock',
    );
    if (!authenticated) {
      return 'Biometric verification failed or was cancelled.';
    }

    biometricEnabled = true;
    await _persistSettings();
    notifyListeners();
    return 'Biometric unlock enabled.';
  }

  void setAppLockEnabled(bool enabled) {
    appLockEnabled = enabled;
    _persistSettings();
    notifyListeners();
  }

  List<TransactionEntry> get currentMonthTransactions {
    final DateTime now = appDateTime;
    return transactions
        .where(
          (TransactionEntry t) =>
              t.date.month == now.month && t.date.year == now.year,
        )
        .toList();
  }

  double get totalIncome {
    return currentMonthTransactions
        .where((TransactionEntry t) => t.type == TransactionType.income)
        .fold(0, (double sum, TransactionEntry t) => sum + t.amount);
  }

  double get totalExpense {
    return currentMonthTransactions
        .where((TransactionEntry t) => t.type == TransactionType.expense)
        .fold(0, (double sum, TransactionEntry t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  List<({String accountId, String accountName, double amount})>
  get currentBalanceAccountBreakdown {
    final List<({String accountId, String accountName, double amount})>
    breakdown = <({String accountId, String accountName, double amount})>[];
    for (final FinanceAccount account in accounts) {
      if (!account.isLiability) {
        breakdown.add((
          accountId: account.id,
          accountName: account.name,
          amount: account.balance,
        ));
        continue;
      }
      if (includeLiabilitiesInCurrentBalance) {
        breakdown.add((
          accountId: account.id,
          accountName: account.name,
          amount: -account.balance,
        ));
      }
    }
    return breakdown;
  }

  double get totalAccountBalance {
    if (accounts.isEmpty) {
      return balance;
    }
    return currentBalanceAccountBreakdown.fold(0, (
      double sum,
      ({String accountId, String accountName, double amount}) item,
    ) {
      return sum + item.amount;
    });
  }

  double goalsSavedByAccount(String accountId) {
    return goalSavingsBreakdownByAccount(accountId).fold(
      0,
      (double sum, ({String goalName, double amount}) item) =>
          sum + item.amount,
    );
  }

  List<({String goalName, double amount})> goalSavingsBreakdownByAccount(
    String accountId,
  ) {
    final Map<String, double> byGoal = <String, double>{};

    for (final TransactionEntry tx in transactions) {
      if (tx.type != TransactionType.expense || tx.accountId != accountId) {
        continue;
      }
      if (tx.title.startsWith('Goal funding:')) {
        final String goalName = tx.title
            .replaceFirst('Goal funding:', '')
            .trim();
        if (goalName.isEmpty) {
          continue;
        }
        byGoal[goalName] = (byGoal[goalName] ?? 0) + tx.amount;
      }
    }

    return byGoal.entries
        .map((MapEntry<String, double> e) => (goalName: e.key, amount: e.value))
        .toList();
  }

  void setIncludeLiabilitiesInCurrentBalance(bool value) {
    includeLiabilitiesInCurrentBalance = value;
    _persistSettings();
    notifyListeners();
  }

  double get budgetUsage {
    if (monthlyBudget == 0) {
      return 0;
    }
    return (totalExpense / monthlyBudget).clamp(0, 1);
  }

  double get budgetAdherenceScore {
    final double budgetScore = 100 - (budgetUsage * 100);
    final double billPenalty = overdueBills.length * 6;
    final double score = budgetScore - billPenalty;
    return score.clamp(0, 100);
  }

  Map<String, double> get expenseByCategory {
    final Map<String, double> totals = <String, double>{};
    for (final TransactionEntry t in currentMonthTransactions) {
      if (t.type == TransactionType.expense) {
        totals[t.category] = (totals[t.category] ?? 0) + t.amount;
      }
    }
    return totals;
  }

  Map<String, double> get weeklyExpenseByCategory {
    final DateTime now = appDateTime;
    final DateTime start = now.subtract(const Duration(days: 6));
    final Map<String, double> totals = <String, double>{};
    for (final TransactionEntry t in transactions) {
      if (t.type != TransactionType.expense) {
        continue;
      }
      if (t.date.isBefore(start) || t.date.isAfter(now)) {
        continue;
      }
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  Map<String, double> get dailyExpenseByCategory {
    final DateTime now = appDateTime;
    final Map<String, double> totals = <String, double>{};
    for (final TransactionEntry t in transactions) {
      if (t.type != TransactionType.expense) {
        continue;
      }
      final bool sameDay =
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day;
      if (!sameDay) {
        continue;
      }
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  List<double> get last7DayExpenses {
    final DateTime today = appDateTime;
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    final List<double> totals = List<double>.filled(7, 0);

    for (final TransactionEntry t in transactions) {
      if (t.type != TransactionType.expense) {
        continue;
      }
      final DateTime day = DateTime(t.date.year, t.date.month, t.date.day);
      if (day.isBefore(start) || day.isAfter(today)) {
        continue;
      }
      final int index = day.difference(start).inDays;
      if (index >= 0 && index < 7) {
        totals[index] += t.amount;
      }
    }

    return totals;
  }

  List<double> get last30DayExpenses {
    final DateTime today = appDateTime;
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 29));
    final List<double> totals = List<double>.filled(30, 0);

    for (final TransactionEntry t in transactions) {
      if (t.type != TransactionType.expense) {
        continue;
      }
      final DateTime day = DateTime(t.date.year, t.date.month, t.date.day);
      if (day.isBefore(start) || day.isAfter(today)) {
        continue;
      }
      final int index = day.difference(start).inDays;
      if (index >= 0 && index < 30) {
        totals[index] += t.amount;
      }
    }

    return totals;
  }

  Map<String, double> spendingTrendByCategory(TrendWindow window) {
    final DateTime now = appDateTime;
    final DateTime start;
    switch (window) {
      case TrendWindow.week:
        start = now.subtract(const Duration(days: 6));
      case TrendWindow.month:
        start = DateTime(now.year, now.month, 1);
      case TrendWindow.quarter:
        start = DateTime(now.year, now.month - 2, 1);
      case TrendWindow.year:
        start = DateTime(now.year, 1, 1);
    }

    final Map<String, double> trend = <String, double>{};
    for (final TransactionEntry tx in transactions) {
      if (tx.type != TransactionType.expense) {
        continue;
      }
      if (tx.date.isBefore(start) || tx.date.isAfter(now)) {
        continue;
      }
      trend[tx.category] = (trend[tx.category] ?? 0) + tx.amount;
    }
    return trend;
  }

  double get endOfMonthForecastBalance {
    final DateTime now = appDateTime;
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final DateTime monthEnd = DateTime(now.year, now.month + 1, 0);
    final int elapsed = math.max(1, now.difference(monthStart).inDays + 1);
    final int remaining = math.max(0, monthEnd.difference(now).inDays);

    final double dailyNet = balance / elapsed;
    return balance + (dailyNet * remaining);
  }

  double get netWorth {
    if (accounts.isEmpty) {
      return balance;
    }
    return accounts.fold(0, (double sum, FinanceAccount account) {
      return sum + (account.isLiability ? -account.balance : account.balance);
    });
  }

  double get totalGoalsSaved {
    return goals.fold(
      0,
      (double sum, SavingsGoal goal) => sum + goal.currentAmount,
    );
  }

  List<({String goalName, double amount})> get goalSavingsBreakdown {
    return goals
        .map(
          (SavingsGoal goal) =>
              (goalName: goal.name, amount: goal.currentAmount),
        )
        .toList();
  }

  List<double> get netWorthHistory {
    final List<double> history = <double>[];
    double running = netWorth;
    for (int i = 0; i < 4; i++) {
      running -= (i * 40);
      history.add(running);
    }
    return history.reversed.toList();
  }

  List<GoalInsight> get goalInsights {
    final DateTime now = appDateTime;
    return goals.map((SavingsGoal goal) {
      final int monthsToGoal = math.max(
        1,
        ((goal.deadline.difference(now).inDays) / 30).ceil(),
      );
      final double remaining = math.max(
        0,
        goal.targetAmount - goal.currentAmount,
      );
      return GoalInsight(
        goalName: goal.name,
        monthsToGoal: monthsToGoal,
        requiredMonthlyContribution: remaining / monthsToGoal,
      );
    }).toList();
  }

  List<BillReminder> get overdueBills {
    return billReminders
        .where((BillReminder bill) => bill.isOverdue(appDateTime))
        .toList();
  }

  List<BillReminder> get dueSoonBills {
    return billReminders
        .where((BillReminder bill) => bill.isDueSoon(appDateTime))
        .toList();
  }

  List<String> get smartBillAlerts {
    final List<String> alerts = <String>[];
    for (final BillReminder bill in dueSoonBills) {
      alerts.add(
        '${bill.title} is due soon (${bill.dueDate.day}/${bill.dueDate.month}).',
      );
    }
    for (final BillReminder bill in overdueBills) {
      alerts.add('${bill.title} is overdue.');
    }
    alerts.addAll(subscriptionAlerts);
    alerts.addAll(budgetActionReminders());
    return alerts;
  }

  int get savingsStreakWeeks {
    int streak = 0;
    DateTime cursor = appDateTime;
    while (streak < 12) {
      final DateTime weekStart = cursor.subtract(
        Duration(days: cursor.weekday - 1),
      );
      final DateTime weekEnd = weekStart.add(const Duration(days: 6));
      double weekIncome = 0;
      double weekExpense = 0;

      for (final TransactionEntry tx in transactions) {
        if (tx.date.isBefore(weekStart) || tx.date.isAfter(weekEnd)) {
          continue;
        }
        if (tx.type == TransactionType.income) {
          weekIncome += tx.amount;
        } else {
          weekExpense += tx.amount;
        }
      }

      if (weekIncome > 0 && weekExpense <= weekIncome) {
        streak += 1;
        cursor = weekStart.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  List<String> get personalizedTips {
    final List<String> tips = <String>[];
    if (budgetUsage > 0.9) {
      tips.add('You are close to your budget cap. Consider a low-spend week.');
    }
    final Map<String, double> trend = spendingTrendByCategory(
      TrendWindow.month,
    );
    if ((trend['Food'] ?? 0) > (categoryBudgets['Food'] ?? 0)) {
      tips.add('Food spend crossed your plan. Try meal planning for 3 days.');
    }
    if (overdueBills.isNotEmpty) {
      tips.add('Pay overdue bills first to avoid late fees and score impact.');
    }
    if (subscriptionAlerts.isNotEmpty) {
      tips.add(subscriptionAlerts.first);
    }
    final List<String> moneyActions = budgetActionReminders();
    if (moneyActions.isNotEmpty) {
      tips.add(moneyActions.first);
    }
    if (tips.isEmpty) {
      tips.add(
        'Great control this month. Keep using category limits and reminders.',
      );
    }
    return tips;
  }

  List<WeeklyReviewCard> get weeklyReviewCards {
    return <WeeklyReviewCard>[
      WeeklyReviewCard(
        title: 'Budget Score',
        description:
            'You are at ${budgetAdherenceScore.toStringAsFixed(0)} / 100 this week.',
      ),
      WeeklyReviewCard(
        title: 'Forecast',
        description:
            'Projected month-end balance: $currencySymbol${endOfMonthForecastBalance.toStringAsFixed(0)}',
      ),
      WeeklyReviewCard(
        title: 'Savings Streak',
        description: 'Current streak is $savingsStreakWeeks week(s).',
      ),
    ];
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  String suggestCategory({required String title, String? merchant}) {
    final String raw =
        '${title.toLowerCase()} ${(merchant ?? '').toLowerCase()}';

    for (final CategoryRule rule in categoryRules) {
      if (raw.contains(rule.keyword.toLowerCase())) {
        return rule.category;
      }
    }

    final String? historyCategory = merchant == null
        ? null
        : merchantCategoryHistory[merchant.toLowerCase()];
    if (historyCategory != null) {
      return historyCategory;
    }

    return 'Uncategorized';
  }

  final Map<String, String> merchantCategoryHistory = <String, String>{};

  void addCategoryRule(String keyword, String category) {
    if (keyword.trim().isEmpty || category.trim().isEmpty) {
      return;
    }
    categoryRules.add(
      CategoryRule(
        keyword: keyword.trim().toLowerCase(),
        category: category.trim(),
      ),
    );
    customCategories.add(category.trim());
    _queueFinancePersist();
    notifyListeners();
  }

  void addCustomTag(String tag) {
    if (tag.trim().isEmpty) {
      return;
    }
    customTags.add(tag.trim());
    _queueFinancePersist();
    notifyListeners();
  }

  void addTransaction(TransactionEntry entry) {
    final String category = entry.category == 'Auto'
        ? suggestCategory(title: entry.title, merchant: entry.merchant)
        : entry.category;

    final TransactionEntry normalized = TransactionEntry(
      id: entry.id,
      title: entry.title,
      category: category,
      amount: entry.amount,
      date: entry.date,
      type: entry.type,
      accountId: entry.accountId,
      merchant: entry.merchant,
      tags: List<String>.from(entry.tags),
      splitParts: List<TransactionSplitPart>.from(entry.splitParts),
      updatedAt: DateTime.now(),
    );

    transactions.insert(0, normalized);
    final double autoSaved = _applySavingsAutomation(normalized);
    if (normalized.merchant != null && normalized.merchant!.trim().isNotEmpty) {
      merchantCategoryHistory[normalized.merchant!.toLowerCase()] =
          normalized.category;
    }
    _applyAccountImpact(normalized);
    auditLogs.insert(
      0,
      TransactionAuditLog(
        timestamp: DateTime.now(),
        action: 'create',
        transactionTitle: normalized.title,
        amount: normalized.amount,
      ),
    );
    if (autoSaved > 0) {
      auditLogs.insert(
        0,
        TransactionAuditLog(
          timestamp: DateTime.now(),
          action: 'automation',
          transactionTitle: 'Auto-save to ${goals.first.name}',
          amount: autoSaved,
        ),
      );
    }
    final List<String> alerts = budgetAlerts();
    if (_notificationsAvailable && alerts.isNotEmpty) {
      int idBase = DateTime.now().millisecondsSinceEpoch % 100000;
      for (final String alert in alerts.take(3)) {
        unawaited(
          _notificationService.showInstantNotification(
            id: idBase++,
            title: 'Budget Alert',
            body: alert,
          ),
        );
      }
    }
    _queueFinancePersist();
    notifyListeners();
  }

  void addSplitTransaction({
    required String title,
    required DateTime date,
    required TransactionType type,
    required List<TransactionSplitPart> parts,
    String? accountId,
    String? merchant,
    List<String>? tags,
  }) {
    final double total = parts.fold(
      0,
      (double sum, TransactionSplitPart p) => sum + p.amount,
    );
    if (total <= 0) {
      return;
    }

    addTransaction(
      TransactionEntry(
        title: title,
        category: 'Split',
        amount: total,
        date: date,
        type: type,
        accountId: accountId,
        merchant: merchant,
        tags: tags,
        splitParts: parts,
      ),
    );
  }

  void editTransaction(String id, TransactionEntry updated) {
    final int index = transactions.indexWhere(
      (TransactionEntry tx) => tx.id == id,
    );
    if (index < 0) {
      return;
    }

    final TransactionEntry previous = transactions[index];
    _revertAccountImpact(previous);

    final TransactionEntry replacement = TransactionEntry(
      id: id,
      title: updated.title,
      category: updated.category,
      amount: updated.amount,
      date: updated.date,
      type: updated.type,
      accountId: updated.accountId,
      merchant: updated.merchant,
      tags: updated.tags,
      splitParts: updated.splitParts,
      updatedAt: DateTime.now(),
    );

    transactions[index] = replacement;
    _applyAccountImpact(replacement);
    auditLogs.insert(
      0,
      TransactionAuditLog(
        timestamp: DateTime.now(),
        action: 'edit',
        transactionTitle: replacement.title,
        amount: replacement.amount,
      ),
    );
    _queueFinancePersist();
    notifyListeners();
  }

  void removeTransaction(String id) {
    final int index = transactions.indexWhere(
      (TransactionEntry tx) => tx.id == id,
    );
    if (index < 0) {
      return;
    }
    final TransactionEntry removed = transactions.removeAt(index);
    _revertAccountImpact(removed);
    auditLogs.insert(
      0,
      TransactionAuditLog(
        timestamp: DateTime.now(),
        action: 'delete',
        transactionTitle: removed.title,
        amount: removed.amount,
      ),
    );
    _queueFinancePersist();
    notifyListeners();
  }

  void _applyAccountImpact(TransactionEntry tx) {
    if (tx.accountId == null) {
      return;
    }
    final FinanceAccount? account = _findAccount(tx.accountId!);
    if (account == null) {
      return;
    }
    final double signed = tx.type == TransactionType.expense
        ? -tx.amount
        : tx.amount;
    account.balance += signed;
  }

  void _revertAccountImpact(TransactionEntry tx) {
    if (tx.accountId == null) {
      return;
    }
    final FinanceAccount? account = _findAccount(tx.accountId!);
    if (account == null) {
      return;
    }
    final double signed = tx.type == TransactionType.expense
        ? -tx.amount
        : tx.amount;
    account.balance -= signed;
  }

  FinanceAccount? _findAccount(String id) {
    try {
      return accounts.firstWhere((FinanceAccount account) => account.id == id);
    } catch (_) {
      return null;
    }
  }

  String transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) {
    if (amount <= 0) {
      return 'Transfer amount must be greater than zero.';
    }

    final FinanceAccount? from = _findAccount(fromAccountId);
    final FinanceAccount? to = _findAccount(toAccountId);
    if (from == null || to == null) {
      return 'Account not found.';
    }

    if (from.balance < amount) {
      return 'Insufficient balance in source account.';
    }

    from.balance -= amount;
    to.balance += amount;

    final DateTime now = DateTime.now();
    transactions.insertAll(0, <TransactionEntry>[
      TransactionEntry(
        title: 'Transfer to ${to.name}',
        category: 'Transfer',
        amount: amount,
        date: now,
        type: TransactionType.expense,
        accountId: from.id,
      ),
      TransactionEntry(
        title: 'Transfer from ${from.name}',
        category: 'Transfer',
        amount: amount,
        date: now,
        type: TransactionType.income,
        accountId: to.id,
      ),
    ]);

    _queueFinancePersist();
    notifyListeners();
    return 'Transfer completed.';
  }

  String addFinanceAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    int? iconCodePoint,
    int? colorValue,
  }) {
    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      return 'Account name is required.';
    }
    if (initialBalance < 0) {
      return 'Initial balance cannot be negative.';
    }

    final bool exists = accounts.any(
      (FinanceAccount account) =>
          account.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (exists) {
      return 'An account with this name already exists.';
    }

    final String id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    accounts.add(
      FinanceAccount(
        id: id,
        name: cleanName,
        type: type,
        balance: initialBalance,
        iconCodePoint:
            iconCodePoint ??
            (type == AccountType.bank
                ? Icons.account_balance.codePoint
                : type == AccountType.creditCard
                ? Icons.credit_card.codePoint
                : Icons.account_balance_wallet.codePoint),
        colorValue:
            colorValue ??
            (type == AccountType.bank
                ? 0xFF1E429F
                : type == AccountType.creditCard
                ? 0xFFD64545
                : 0xFF0E9F6E),
        isLiability: type == AccountType.creditCard,
      ),
    );
    _queueFinancePersist();
    notifyListeners();
    return 'Account added successfully.';
  }

  String removeFinanceAccount(String accountId) {
    if (accounts.length <= 1) {
      return 'At least one account must remain.';
    }

    final int index = accounts.indexWhere(
      (FinanceAccount account) => account.id == accountId,
    );
    if (index < 0) {
      return 'Account not found.';
    }

    final bool isUsed = transactions.any(
      (TransactionEntry tx) => tx.accountId == accountId,
    );
    if (isUsed) {
      return 'Cannot remove account with linked transactions.';
    }

    accounts.removeAt(index);
    _queueFinancePersist();
    notifyListeners();
    return 'Account removed.';
  }

  void addGoal(SavingsGoal goal) {
    goals.add(goal);
    _queueFinancePersist();
    notifyListeners();
  }

  String removeGoalAt(int goalIndex) {
    if (goalIndex < 0 || goalIndex >= goals.length) {
      return 'Selected goal not found.';
    }
    final String name = goals[goalIndex].name;
    goals.removeAt(goalIndex);
    if (budgetHealthGoalName == name) {
      budgetHealthGoalName = goals.isEmpty ? null : goals.first.name;
      _persistSettings();
    }
    _queueFinancePersist();
    notifyListeners();
    return 'Goal "$name" deleted.';
  }

  SavingsGoal? get selectedBudgetHealthGoal {
    if (goals.isEmpty) {
      return null;
    }
    if (budgetHealthGoalName == null || budgetHealthGoalName!.trim().isEmpty) {
      return goals.first;
    }
    for (final SavingsGoal goal in goals) {
      if (goal.name == budgetHealthGoalName) {
        return goal;
      }
    }
    return goals.first;
  }

  void setBudgetHealthGoalName(String? name) {
    final String? trimmed = name?.trim();
    budgetHealthGoalName = (trimmed == null || trimmed.isEmpty)
        ? null
        : trimmed;
    _persistSettings();
    notifyListeners();
  }

  String sendCashToGoal({
    required int goalIndex,
    required String fromAccountId,
    required double amount,
  }) {
    if (goalIndex < 0 || goalIndex >= goals.length) {
      return 'Selected goal not found.';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero.';
    }

    final FinanceAccount? account = _findAccount(fromAccountId);
    if (account == null) {
      return 'Selected account not found.';
    }
    if (account.isLiability) {
      return 'Cannot fund goals from liability accounts.';
    }
    if (account.balance < amount) {
      return 'Insufficient balance in selected account.';
    }

    final SavingsGoal goal = goals[goalIndex];
    account.balance -= amount;
    goals[goalIndex] = SavingsGoal(
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount + amount,
      deadline: goal.deadline,
    );

    transactions.insert(
      0,
      TransactionEntry(
        title: 'Goal funding: ${goal.name}',
        category: 'Savings',
        amount: amount,
        date: appDateTime,
        type: TransactionType.expense,
        accountId: account.id,
        tags: const <String>['Goal'],
      ),
    );

    auditLogs.insert(
      0,
      TransactionAuditLog(
        timestamp: DateTime.now(),
        action: 'goal_funding',
        transactionTitle: goal.name,
        amount: amount,
      ),
    );

    _queueFinancePersist();
    notifyListeners();
    return 'Added $currencySymbol${amount.toStringAsFixed(2)} to ${goal.name}.';
  }

  void setBudget(double value) {
    monthlyBudget = value;
    _persistSettings();
    notifyListeners();
  }

  void setCategoryBudget({
    required String category,
    required double value,
    required BudgetPeriod period,
  }) {
    if (value <= 0) {
      return;
    }

    switch (period) {
      case BudgetPeriod.daily:
        dailyCategoryBudgets[category] = value;
      case BudgetPeriod.weekly:
        weeklyCategoryBudgets[category] = value;
      case BudgetPeriod.monthly:
        categoryBudgets[category] = value;
    }
    customCategories.add(category);
    _persistSettings();
    _queueFinancePersist();
    notifyListeners();
  }

  String addCustomCategory(String name) {
    final String category = name.trim();
    if (category.isEmpty) {
      return 'Category name is required.';
    }
    final bool exists = customCategories.any(
      (String existing) => existing.toLowerCase() == category.toLowerCase(),
    );
    if (exists) {
      return 'Category already exists.';
    }

    customCategories.add(category);
    _persistSettings();
    _queueFinancePersist();
    notifyListeners();
    return 'Category added.';
  }

  String removeCustomCategory(String category) {
    final String target = category.trim();
    if (target.isEmpty) {
      return 'Category not found.';
    }

    final bool usedByTransactions = transactions.any(
      (TransactionEntry tx) =>
          tx.category.toLowerCase() == target.toLowerCase(),
    );
    if (usedByTransactions) {
      return 'Cannot delete category used by transactions.';
    }

    final String? existing = customCategories.cast<String?>().firstWhere(
      (String? item) => item?.toLowerCase() == target.toLowerCase(),
      orElse: () => null,
    );
    if (existing == null) {
      return 'Category not found.';
    }

    customCategories.remove(existing);
    categoryBudgets.remove(existing);
    weeklyCategoryBudgets.remove(existing);
    dailyCategoryBudgets.remove(existing);
    _persistSettings();
    _queueFinancePersist();
    notifyListeners();
    return 'Category deleted.';
  }

  void updateProfile({
    required String name,
    required String email,
    String? profileImageUrl,
  }) {
    userName = name.trim();
    userEmail = email.trim();
    if (profileImageUrl != null) {
      userProfileImageUrl = profileImageUrl.trim();
    }
    unawaited(_persistAccountData());
    _persistSettings();
    notifyListeners();
  }

  String changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (oldPassword != _password) {
      return 'Current password is incorrect.';
    }
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }
    if (newPassword != confirmPassword) {
      return 'New password and confirm password do not match.';
    }

    _password = newPassword;
    unawaited(_persistAccountData());
    return 'Password updated successfully.';
  }

  String createAccount({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final String cleanName = name.trim();
    final String cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      return 'Name is required.';
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Email is invalid.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (password != confirmPassword) {
      return 'Password and confirm password do not match.';
    }

    userName = cleanName;
    userEmail = cleanEmail;
    _password = password;

    // A newly created app account should not inherit previously stored finance data.
    transactions.clear();
    goals.clear();
    categoryBudgets.clear();
    dailyCategoryBudgets.clear();
    weeklyCategoryBudgets.clear();
    accounts.clear();
    recurringRules.clear();
    billReminders.clear();
    fixedDeposits.clear();
    categoryRules.clear();
    subscriptions.clear();
    hiddenDashboardWidgets.clear();
    auditLogs.clear();
    budgetHealthGoalName = null;
    _lastMoneyActionReminderAt = null;

    unawaited(_persistAccountData());
    _persistSettings();
    _queueFinancePersist();
    notifyListeners();
    return 'Account created successfully.';
  }

  bool validateLogin({required String email, required String password}) {
    return email.trim().toLowerCase() == userEmail.toLowerCase() &&
        password == _password;
  }

  void adjustAppDateTime(DateTime value) {
    appDateTime = value;
    _persistSettings();
    unawaited(checkFixedDepositReminders());
    unawaited(checkSubscriptionAndBudgetReminders());
    notifyListeners();
  }

  void addRecurringRule(RecurringTransactionRule rule) {
    recurringRules.add(rule);
    notifyListeners();
  }

  void applyRecurringTransactionsForDate(DateTime date, {bool notify = true}) {
    bool changed = false;
    for (final RecurringTransactionRule rule in recurringRules) {
      while (!rule.nextRun.isAfter(date)) {
        addTransaction(
          TransactionEntry(
            title: rule.title,
            category: rule.category,
            amount: rule.amount,
            date: rule.nextRun,
            type: rule.type,
            accountId: rule.accountId,
            tags: const <String>['Recurring'],
          ),
        );
        rule.nextRun = rule.nextRun.add(Duration(days: rule.frequencyDays));
        changed = true;
      }
    }
    if (changed && notify) {
      notifyListeners();
    }
  }

  void addBillReminder(BillReminder bill) {
    billReminders.add(bill);
    notifyListeners();
  }

  void markBillPaid(String billId, bool paid) {
    for (final BillReminder bill in billReminders) {
      if (bill.id == billId) {
        bill.isPaid = paid;
        break;
      }
    }
    notifyListeners();
  }

  Map<String, dynamic> buildTaxReadyReport({required int year}) {
    final Iterable<TransactionEntry> expenses = transactions.where(
      (TransactionEntry tx) =>
          tx.type == TransactionType.expense && tx.date.year == year,
    );

    final Map<String, double> deductibleByCategory = <String, double>{};
    for (final TransactionEntry tx in expenses) {
      deductibleByCategory[tx.category] =
          (deductibleByCategory[tx.category] ?? 0) + tx.amount;
    }

    return <String, dynamic>{
      'year': year,
      'totalExpense': expenses.fold(
        0.0,
        (double s, TransactionEntry t) => s + t.amount,
      ),
      'byCategory': deductibleByCategory,
    };
  }

  List<TransactionEntry> filteredTransactions(ReportFilter filter) {
    return transactions.where((TransactionEntry tx) {
      if (filter.startDate != null && tx.date.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && tx.date.isAfter(filter.endDate!)) {
        return false;
      }
      if (filter.accountId != null && tx.accountId != filter.accountId) {
        return false;
      }
      if (filter.tag != null && !tx.tags.contains(filter.tag)) {
        return false;
      }
      if (filter.minAmount != null && tx.amount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }

  String get financialHealthSnapshot {
    return 'Balance: $currencySymbol${balance.toStringAsFixed(2)}\n'
        'Budget usage: ${(budgetUsage * 100).toStringAsFixed(1)}%\n'
        'Budget score: ${budgetAdherenceScore.toStringAsFixed(0)}/100\n'
        'Net worth: $currencySymbol${netWorth.toStringAsFixed(2)}\n'
        'Overdue bills: ${overdueBills.length}\n'
        'Savings streak: $savingsStreakWeeks week(s)';
  }

  String generateBackupPayload() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'user': <String, String>{'name': userName, 'email': userEmail},
      'transactions': transactions
          .map(
            (TransactionEntry tx) => <String, dynamic>{
              'id': tx.id,
              'title': tx.title,
              'category': tx.category,
              'amount': tx.amount,
              'date': tx.date.toIso8601String(),
              'type': tx.type.name,
              'accountId': tx.accountId,
              'merchant': tx.merchant,
              'tags': tx.tags,
              'updatedAt': tx.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'goals': goals
          .map(
            (SavingsGoal goal) => <String, dynamic>{
              'name': goal.name,
              'targetAmount': goal.targetAmount,
              'currentAmount': goal.currentAmount,
              'deadline': goal.deadline.toIso8601String(),
            },
          )
          .toList(),
      'accounts': accounts
          .map(
            (FinanceAccount account) => <String, dynamic>{
              'id': account.id,
              'name': account.name,
              'type': account.type.name,
              'balance': account.balance,
              'isLiability': account.isLiability,
            },
          )
          .toList(),
      'bills': billReminders
          .map(
            (BillReminder bill) => <String, dynamic>{
              'id': bill.id,
              'title': bill.title,
              'amount': bill.amount,
              'dueDate': bill.dueDate.toIso8601String(),
              'isPaid': bill.isPaid,
            },
          )
          .toList(),
    };

    lastBackupAt = DateTime.now();
    notifyListeners();
    return jsonEncode(payload);
  }

  String generateEncryptedBackupPayload() {
    final String raw = generateBackupPayload();
    final List<int> bytes = utf8.encode(raw);
    final int key = (_appPin ?? userEmail).hashCode & 0xFF;
    final List<int> encrypted = bytes.map((int byte) => byte ^ key).toList();
    return base64Encode(encrypted);
  }

  String importEncryptedBackupPayload(String encodedPayload) {
    try {
      final List<int> encrypted = base64Decode(encodedPayload);
      final int key = (_appPin ?? userEmail).hashCode & 0xFF;
      final List<int> plain = encrypted.map((int byte) => byte ^ key).toList();
      final String jsonString = utf8.decode(plain);
      final Map<String, dynamic> payload =
          jsonDecode(jsonString) as Map<String, dynamic>;
      _mergePayload(payload);
      notifyListeners();
      return 'Backup imported and merged.';
    } catch (_) {
      return 'Failed to import backup payload.';
    }
  }

  void _mergePayload(Map<String, dynamic> payload) {
    final List<dynamic> incomingTransactions =
        (payload['transactions'] as List<dynamic>? ?? <dynamic>[]);

    for (final dynamic item in incomingTransactions) {
      final Map<String, dynamic> tx = item as Map<String, dynamic>;
      final String id = (tx['id'] ?? '').toString();
      if (id.isEmpty) {
        continue;
      }

      final int localIndex = transactions.indexWhere(
        (TransactionEntry local) => local.id == id,
      );
      final DateTime incomingUpdated =
          DateTime.tryParse((tx['updatedAt'] ?? '').toString()) ??
          DateTime.now();

      if (localIndex < 0) {
        transactions.add(
          TransactionEntry(
            id: id,
            title: (tx['title'] ?? 'Imported').toString(),
            category: (tx['category'] ?? 'Uncategorized').toString(),
            amount: (tx['amount'] as num?)?.toDouble() ?? 0,
            date:
                DateTime.tryParse((tx['date'] ?? '').toString()) ??
                DateTime.now(),
            type: (tx['type'] ?? 'expense') == 'income'
                ? TransactionType.income
                : TransactionType.expense,
            accountId: tx['accountId']?.toString(),
            merchant: tx['merchant']?.toString(),
            tags: (tx['tags'] as List<dynamic>? ?? <dynamic>[])
                .map((dynamic value) => value.toString())
                .toList(),
            updatedAt: incomingUpdated,
          ),
        );
        continue;
      }

      final TransactionEntry local = transactions[localIndex];
      if (incomingUpdated.isAfter(local.updatedAt)) {
        transactions[localIndex] = TransactionEntry(
          id: id,
          title: (tx['title'] ?? local.title).toString(),
          category: (tx['category'] ?? local.category).toString(),
          amount: (tx['amount'] as num?)?.toDouble() ?? local.amount,
          date: DateTime.tryParse((tx['date'] ?? '').toString()) ?? local.date,
          type: (tx['type'] ?? 'expense') == 'income'
              ? TransactionType.income
              : TransactionType.expense,
          accountId: tx['accountId']?.toString(),
          merchant: tx['merchant']?.toString(),
          tags: (tx['tags'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic value) => value.toString())
              .toList(),
          updatedAt: incomingUpdated,
        );
      }
    }
  }

  String _obfuscate(String value) {
    return base64Encode(utf8.encode(value));
  }

  String _deobfuscate(String value) {
    try {
      return utf8.decode(base64Decode(value));
    } catch (_) {
      return value;
    }
  }

  Future<String> resetApp() async {
    final String preservedName = userName;
    final String preservedEmail = userEmail;
    final String preservedPassword = _password;
    final String preservedProfileImage = userProfileImageUrl;
    final bool preservedAppLockEnabled = appLockEnabled;
    final bool preservedBiometricEnabled = biometricEnabled;
    final String? preservedAppPin = _appPin;

    if (reminderEnabled && _notificationsAvailable) {
      await _notificationService.disableWeeklyReminder();
    }

    selectedIndex = 0;
    reminderEnabled = false;
    monthlyBudget = 4000;
    userName = preservedName;
    userEmail = preservedEmail;
    _password = preservedPassword;
    userProfileImageUrl = preservedProfileImage;
    appDateTime = DateTime.now();
    selectedCurrency = 'USD';
    selectedThemePack = ThemePack.ocean;
    dashboardLayout = DashboardLayout.detailed;
    appLockEnabled = preservedAppLockEnabled;
    biometricEnabled = preservedBiometricEnabled;
    includeLiabilitiesInCurrentBalance = false;
    savingsAutomationEnabled = false;
    savingsAutomationPercent = 10;
    budgetAlertsEnabled = true;
    darkModeEnabled = false;
    themePreset = AppThemePreset.teal;
    localeOption = AppLocaleOption.en;
    cloudSyncEnabled = false;
    cloudSyncEmail = '';
    _appPin = preservedAppPin;
    _lastMoneyActionReminderAt = null;
    await _persistAccountData();

    transactions.clear();
    goals.clear();
    categoryBudgets.clear();
    dailyCategoryBudgets.clear();
    weeklyCategoryBudgets.clear();
    accounts.clear();
    recurringRules.clear();
    billReminders.clear();
    fixedDeposits.clear();
    categoryRules.clear();
    subscriptions.clear();
    dashboardWidgetOrder
      ..clear()
      ..addAll(<DashboardWidgetId>[
        DashboardWidgetId.currentBalance,
        DashboardWidgetId.incomeExpense,
        DashboardWidgetId.netWorthForecast,
        DashboardWidgetId.budgetHealth,
        DashboardWidgetId.gamification,
        DashboardWidgetId.personalizedTips,
        DashboardWidgetId.weeklyTrend,
        DashboardWidgetId.topCategories,
      ]);
    hiddenDashboardWidgets.clear();
    auditLogs.clear();

    await _persistSettings();
    await _persistFinanceData();
    notifyListeners();
    return 'App reset completed.';
  }

  Future<String> deleteAccount() async {
    final String message = await resetApp();
    userName = '';
    userEmail = '';
    userProfileImageUrl = '';
    _password = '';
    appLockEnabled = false;
    biometricEnabled = false;
    _appPin = null;
    await _persistAccountData();
    await _persistSettings();
    notifyListeners();
    return message;
  }

  Future<String> toggleReminder() async {
    if (!_notificationsAvailable) {
      return 'Notifications are not available on this platform/build.';
    }

    if (reminderEnabled) {
      final bool disabled = await _notificationService.disableWeeklyReminder();
      if (!disabled) {
        _notificationsAvailable = false;
        return 'Notifications are not available on this platform/build.';
      }
      reminderEnabled = false;
      notifyListeners();
      return 'Reminder disabled.';
    }

    final bool enabled = await _notificationService.enableWeeklyReminder();
    if (!enabled) {
      _notificationsAvailable = false;
      return 'Notifications are not available on this platform/build.';
    }
    reminderEnabled = true;
    notifyListeners();
    unawaited(checkSubscriptionAndBudgetReminders());
    return 'Weekly reminder enabled successfully.';
  }

  Future<String> exportCsv() async {
    final String filePath = await _exportService.exportCsv(transactions);
    return 'CSV exported: $filePath';
  }

  Future<String> exportPdf() async {
    final String result = await _exportService.exportPdf(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      transactions: transactions,
    );

    if (result == 'shared') {
      return 'PDF report generated.';
    }

    return 'PDF exported: $result';
  }
}
