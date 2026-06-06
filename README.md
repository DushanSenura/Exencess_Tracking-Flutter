# Expenso

Expenso is a Flutter personal finance tracker for managing daily expenses, income, budgets, savings goals, accounts, subscriptions, fixed deposits, reports, reminders, and app security in one local-first mobile/desktop app.

The app is designed around a simple finance workflow: create or sign in to a local account, add accounts and transactions, track budget health, save toward goals, monitor subscriptions and fixed deposits, and use reports/reminders to decide when to pay, save, or slow spending.

Created by NovaCore Tech.

## Features

- Local account signup and login with optional remember-session behavior.
- Onboarding, splash screen, login, create-account, and logout flow.
- App lock with 4-digit PIN and optional biometric unlock.
- Multi-account tracking for bank, cash, wallet, and credit card accounts.
- Income and expense transaction tracking.
- Transaction categories, custom categories, tags, merchants, and split transactions.
- Account transfers and account management.
- Dashboard with current balance, income/expense summary, net worth, forecasts, budget health, savings streaks, trends, top categories, and personalized tips.
- Daily, weekly, and monthly category budget planning.
- Budget threshold alerts at 70%, 90%, and exceeded states.
- Budget action reminders that suggest when to pay essentials, prepare money for subscriptions, save surplus cash, or reduce spending.
- Savings goals with progress tracking, deadlines, and account funding.
- Fixed deposit management with principal, interest rate, start date, maturity date, reminder date, maturity value, close/delete actions, and maturity reminders.
- Subscription center with renewal dates, active/inactive toggles, due-soon labels, delete action, and payment reminders.
- Reports with income/expense totals, trend data, smart bill/subscription/budget alerts, goal insights, and forecast summaries.
- Weekly finance review reminders.
- Immediate local notifications for budget, subscription, fixed-deposit, and money-action reminders.
- CSV and PDF export support.
- Profile editing with image selection.
- Currency selection and simple exchange-rate support.
- Dark mode/theme preset settings.
- Local encrypted backup payload import/export hooks.
- Local cloud-sync placeholder by email using local preferences.

## Architecture

The project follows a lightweight MVVM-style structure:

- `lib/main.dart`
  - Flutter entry point.
  - Initializes widgets and starts `FinanceTrackerApp`.

- `lib/app.dart`
  - App shell and authentication gate.
  - Handles splash, onboarding, login, signup, app lock, biometric unlock, logout, and routing into the finance home.

- `lib/viewmodels/finance_view_model.dart`
  - Main application state and business logic.
  - Owns transactions, accounts, budgets, goals, subscriptions, fixed deposits, reports, settings, reminders, export actions, and persistence coordination.
  - Extends `ChangeNotifier`, and the UI listens with `AnimatedBuilder`.

- `lib/views/financial_home_page.dart`
  - Main authenticated app layout.
  - Builds the bottom navigation pages, floating action buttons, and modal dialogs for adding/editing finance data.

- `lib/views/screens/`
  - Feature screens:
    - `dashboard_screen.dart`
    - `transactions_screen.dart`
    - `budget_planner_screen.dart`
    - `goals_screen.dart`
    - `fd_manage_screen.dart`
    - `reports_screen.dart`
    - `settings_screen.dart`

- `lib/models/`
  - Data models and enums:
    - `transaction_entry.dart`
    - `savings_goal.dart`
    - `finance_feature_models.dart`
    - `account_data.dart`

- `lib/database/`
  - SQLite persistence services:
    - `account_database_service.dart`
    - `finance_database_service.dart`

- `lib/services/`
  - Platform and utility services:
    - `notification_service.dart`
    - `export_service.dart`

- `lib/views/widgets/`
  - Shared UI widgets such as PIN pad, finance cards, and charts.

## Navigation

After login, the main bottom navigation contains:

1. Home
2. Entries
3. Budget
4. Goals
5. FD
6. Reports
7. Settings

The floating action button changes by page:

- Home/Entries: add transaction
- Budget: add budget
- Goals: add goal
- FD: add fixed deposit
- Reports: view report
- Settings: no FAB

Logout clears the remembered session and returns directly to the login page.

## How The System Works

### Authentication

The app uses local account data, not Firebase. Account credentials are stored locally through `AccountDatabaseService`.

Signup creates a local account. Login validates the local email and password. Google Sign-In is still available as a convenience sign-in source, but it creates/uses a local app account from the Google email/name instead of Firebase Auth.

### State Management

`FinanceViewModel` is the central state object. It:

- Loads account data, finance data, and settings at startup.
- Exposes derived values such as balance, income, expense, budget usage, forecasts, alerts, and insights.
- Updates state through methods like `addTransaction`, `addSubscription`, `addFixedDeposit`, `setBudget`, and `sendCashToGoal`.
- Calls `notifyListeners()` so the UI refreshes.

### Persistence

The app stores data locally:

- Account credentials are stored by `AccountDatabaseService`.
- Finance data is stored as a JSON payload in SQLite through `FinanceDatabaseService`.
- User preferences and settings are stored with `shared_preferences`.

The finance payload includes transactions, goals, accounts, budgets, subscriptions, fixed deposits, dashboard widget settings, and related metadata.

### Notifications And Reminders

`NotificationService` wraps `flutter_local_notifications`.

Supported reminders include:

- Weekly finance review.
- Budget threshold alerts.
- Subscription payment reminders.
- Budget action reminders for paying, saving, or reducing spending.
- Fixed deposit maturity reminders.

On unsupported platforms/builds, notifications fail gracefully and the app still shows in-app reminders through dashboard tips and reports.

### Budget And Saving Guidance

The system calculates:

- Budget usage from total expenses divided by monthly budget.
- Remaining monthly budget.
- Upcoming subscription obligations.
- End-of-month forecast.

Based on those values, it suggests actions such as:

- Keep money ready for subscriptions.
- Pay essentials only when over budget.
- Save surplus cash when budget usage is healthy.
- Reduce spending if forecasted cash is tight.

### Fixed Deposits

The FD page tracks:

- Bank/institution name.
- FD/account number.
- Principal.
- Annual interest rate.
- Start and maturity dates.
- Reminder date.
- Expected interest and maturity amount.
- Active/closed state.

FD reminders are checked against the app date and only sent once per day.

## Data Model Summary

Important models include:

- `TransactionEntry`: expense/income records, merchant, tags, splits, account ID, updated timestamp.
- `FinanceAccount`: account name, type, balance, icon/color, liability flag.
- `SavingsGoal`: target, current amount, deadline, progress.
- `BudgetPlan`: category limit by period.
- `SubscriptionPlan`: renewal date, amount, active state, reminder history.
- `FixedDeposit`: principal, interest rate, maturity date, reminder date, expected value.
- `BillReminder`: bill due date and paid state.
- `RecurringTransactionRule`: recurring income/expense rule.

## Dependencies

Main packages:

- `flutter_localizations`
- `cupertino_icons`
- `fl_chart`
- `local_auth`
- `flutter_local_notifications`
- `path_provider`
- `image_picker`
- `pdf`
- `printing`
- `shared_preferences`
- `sqflite`
- `sqflite_common_ffi`
- `path`
- `google_fonts`
- `google_sign_in`

Firebase has been removed from the project.

## Assets

Configured assets:

- `lib/assets/image/Expenso.png`
- `lib/assets/image/NovaCore.png`

Other image files may exist in `lib/assets/image/`, but only configured assets are guaranteed to be bundled.

## Setup

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Analyze:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Platform Notes

- SQLite uses `sqflite` on mobile and `sqflite_common_ffi` on desktop.
- Notifications require platform support and permission.
- Biometric unlock depends on platform support through `local_auth`.
- PDF/CSV export depends on available filesystem/share support.
- Google Sign-In may require platform-specific configuration if used in production.

## Current Limitations

- Data is local-first; there is no real remote backend.
- The cloud-sync feature is currently a local preference-backed placeholder.
- Reminder delivery depends on OS notification permissions and plugin support.
- Password storage is local and intentionally simple for this project; production apps should use stronger credential storage and hashing.
- Some generated Flutter files may need regeneration after dependency changes by running `flutter pub get`.

## Recommended Development Workflow

1. Run `flutter pub get` after dependency changes.
2. Run `dart format lib test`.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. Test key flows manually:
   - signup/login/logout
   - add transaction
   - add budget
   - add goal
   - add subscription
   - add fixed deposit
   - enable reminders
   - export reports

## Project Status

Expenso is an active Flutter finance-tracking project created by NovaCore Tech, with local persistence, personal finance workflows, dashboard/reporting features, reminders, and account security features.
