import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<bool> initialize() async {
    if (kIsWeb) {
      _isReady = false;
      return false;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _isReady = true;
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> enableWeeklyReminder() async {
    if (!_isReady) {
      return false;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'weekly_finance_review',
          'Weekly Finance Review',
          channelDescription:
              'Weekly reminder for budgets, subscriptions, and savings goals.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.periodicallyShow(
        1001,
        'Weekly money check-in',
        'Review budgets, pay subscriptions, and save money for goals this week.',
        RepeatInterval.weekly,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> disableWeeklyReminder() async {
    if (!_isReady) {
      return false;
    }

    try {
      await _plugin.cancel(1001);
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isReady) {
      return false;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Immediate alerts for budget thresholds.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(id, title, body, details);
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> showSubscriptionReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isReady) {
      return false;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'subscription_reminders',
          'Subscription Reminders',
          channelDescription:
              'Alerts for subscriptions that are due soon or due today.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(id, title, body, details);
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> showMoneyActionReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isReady) {
      return false;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'money_action_reminders',
          'Money Action Reminders',
          channelDescription:
              'Budget guidance for paying bills, slowing spending, and saving money.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(id, title, body, details);
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }

  Future<bool> showFixedDepositReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isReady) {
      return false;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fixed_deposit_reminders',
          'Fixed Deposit Reminders',
          channelDescription:
              'Alerts for fixed deposit reminder and maturity dates.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(id, title, body, details);
      return true;
    } on MissingPluginException {
      _isReady = false;
      return false;
    }
  }
}
