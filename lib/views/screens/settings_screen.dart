import 'package:flutter/material.dart';
import 'dart:convert';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userProfileImageUrl,
    required this.appDateTime,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onManageAccounts,
    required this.onManageCategories,
    required this.onAdjustDateTime,
    required this.onResetApp,
    required this.onDeleteAccount,
    required this.onLogout,
    required this.selectedCurrency,
    required this.onSelectCurrency,
    required this.includeLiabilitiesInCurrentBalance,
    required this.onToggleIncludeLiabilities,
    required this.appLockEnabled,
    required this.biometricEnabled,
    required this.onToggleAppLock,
    required this.onToggleBiometric,
    required this.financialSnapshot,
    required this.categoryCount,
    required this.reminderEnabled,
    required this.onToggleReminder,
    required this.onManageSavingsAutomation,
    required this.onOpenSubscriptionCenter,
    required this.onOpenDashboardWidgets,
    required this.onOpenAppearance,
  });

  final String userName;
  final String userEmail;
  final String userProfileImageUrl;
  final DateTime appDateTime;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onManageAccounts;
  final VoidCallback onManageCategories;
  final VoidCallback onAdjustDateTime;
  final VoidCallback onResetApp;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;
  final String selectedCurrency;
  final VoidCallback onSelectCurrency;
  final bool includeLiabilitiesInCurrentBalance;
  final ValueChanged<bool> onToggleIncludeLiabilities;
  final bool appLockEnabled;
  final bool biometricEnabled;
  final ValueChanged<bool> onToggleAppLock;
  final ValueChanged<bool> onToggleBiometric;
  final String financialSnapshot;
  final int categoryCount;
  final bool reminderEnabled;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onManageSavingsAutomation;
  final VoidCallback onOpenSubscriptionCenter;
  final VoidCallback onOpenDashboardWidgets;
  final VoidCallback onOpenAppearance;

  Widget _sectionTitle(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasProfileImage = userProfileImageUrl.trim().isNotEmpty;
    final bool isNetworkImage =
        userProfileImageUrl.startsWith('http://') ||
        userProfileImageUrl.startsWith('https://');

    ImageProvider<Object>? profileImage;
    if (hasProfileImage && isNetworkImage) {
      profileImage = NetworkImage(userProfileImageUrl);
    } else if (hasProfileImage) {
      try {
        profileImage = MemoryImage(base64Decode(userProfileImageUrl));
      } catch (_) {
        profileImage = null;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _sectionTitle(context, 'Profile'),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              foregroundImage: profileImage,
              child: hasProfileImage ? null : const Icon(Icons.person),
            ),
            title: Text(userName),
            subtitle: Text(userEmail),
            trailing: const Icon(Icons.edit),
            onTap: onEditProfile,
          ),
        ),
        const SizedBox(height: 12),

        _sectionTitle(context, 'Account & Security'),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                subtitle: const Text('Update account password'),
                onTap: onChangePassword,
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: appLockEnabled,
                onChanged: onToggleAppLock,
                title: const Text('App Lock with PIN'),
                subtitle: const Text(
                  'Require a 4-digit PIN to open finance dashboard',
                ),
                secondary: const Icon(Icons.shield_outlined),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: biometricEnabled,
                onChanged: onToggleBiometric,
                title: const Text('Biometric Unlock'),
                subtitle: const Text('Allow biometric auth when available'),
                secondary: const Icon(Icons.fingerprint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _sectionTitle(context, 'Finance Setup'),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Manage Accounts'),
                subtitle: const Text('Manage multi-bank and wallet accounts'),
                onTap: onManageAccounts,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage Categories'),
                subtitle: Text('$categoryCount categories available'),
                onTap: onManageCategories,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Currency'),
                subtitle: Text(selectedCurrency),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSelectCurrency,
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: includeLiabilitiesInCurrentBalance,
                onChanged: onToggleIncludeLiabilities,
                secondary: const Icon(Icons.credit_score_outlined),
                title: const Text('Include Credit Card Debt'),
                subtitle: const Text(
                  'Subtract liabilities from Home current balance',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Adjust App Date & Time'),
                subtitle: Text(
                  '${appDateTime.day}/${appDateTime.month}/${appDateTime.year}  ${appDateTime.hour.toString().padLeft(2, '0')}:${appDateTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: onAdjustDateTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _sectionTitle(context, 'Automation & Personalization'),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                value: reminderEnabled,
                onChanged: onToggleReminder,
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Enable Reminder'),
                subtitle: Text(
                  reminderEnabled
                      ? 'Budget, subscription, and saving reminders are enabled'
                      : 'Budget, subscription, and saving reminders are disabled',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Saving Automation'),
                subtitle: const Text('Move a percentage of income to goals'),
                onTap: onManageSavingsAutomation,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.subscriptions_outlined),
                title: const Text('Subscription Center'),
                subtitle: const Text('Manage recurring subscriptions'),
                onTap: onOpenSubscriptionCenter,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Dashboard Widgets'),
                subtitle: const Text('Show, hide, and reorder widgets'),
                onTap: onOpenDashboardWidgets,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: const Text('Adjust app appearance'),
                onTap: onOpenAppearance,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _sectionTitle(context, 'Danger Zone'),
        Card(
          color: const Color(0xFFFFF3F2),
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.restart_alt,
                  color: Color(0xFFD64545),
                ),
                title: const Text('Reset App'),
                subtitle: const Text('Clear app data and restore defaults'),
                onTap: onResetApp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFD64545),
                ),
                title: const Text('Delete Account'),
                subtitle: const Text(
                  'Delete your account and all finance data',
                ),
                onTap: onDeleteAccount,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                subtitle: const Text('Sign out and return to login screen'),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
