import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/finance_feature_models.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../viewmodels/finance_view_model.dart';
import 'screens/budget_planner_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fd_manage_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transactions_screen.dart';
import 'widgets/pin_pad.dart';

class FinancialHomePage extends StatefulWidget {
  const FinancialHomePage({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  final FinanceViewModel viewModel;
  final VoidCallback onLogout;

  @override
  State<FinancialHomePage> createState() => _FinancialHomePageState();
}

class _FinancialHomePageState extends State<FinancialHomePage> {
  late final FinanceViewModel _viewModel;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPageSwitching = false;

  static const List<IconData> _accountIconOptions = <IconData>[
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.wallet,
    Icons.attach_money,
  ];

  static const List<Color> _accountColorOptions = <Color>[
    Color(0xFF1E429F),
    Color(0xFF0E9F6E),
    Color(0xFFD64545),
    Color(0xFFB45309),
    Color(0xFF6D28D9),
    Color(0xFF0F766E),
  ];

  static const List<String> _reportPeriods = <String>['Day', 'Week', 'Month'];

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.cash:
        return 'Cash';
      case AccountType.wallet:
        return 'Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
    }
  }

  Future<void> _handlePageChange(int index) async {
    if (_isPageSwitching || index == _viewModel.selectedIndex) {
      return;
    }
    setState(() {
      _isPageSwitching = true;
    });
    // Keep this short so navigation still feels snappy.
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _viewModel.setSelectedIndex(index);
    if (!mounted) {
      return;
    }
    setState(() {
      _isPageSwitching = false;
    });
  }

  Widget _buildPageSwitchLoadingOverlay(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: colorScheme.scrim.withValues(alpha: 0.18),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading page...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAccountDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController(
      text: '0',
    );
    AccountType selectedType = AccountType.bank;
    IconData selectedIcon = Icons.account_balance;
    Color selectedColor = const Color(0xFF1E429F);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Account'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: AccountType.values.map((AccountType type) {
                        return DropdownMenuItem<AccountType>(
                          value: type,
                          child: Text(_accountTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (AccountType? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            'Initial Balance (${_viewModel.selectedCurrency})',
                      ),
                      validator: (String? value) {
                        final double? parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Icon',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _accountIconOptions.map((IconData icon) {
                        final bool isSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : Theme.of(context).colorScheme.outline,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(icon, color: selectedColor, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Color',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: _accountColorOptions.map((Color color) {
                        final bool isSelected =
                            selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final String message = _viewModel.addFinanceAccount(
                      name: nameController.text,
                      type: selectedType,
                      initialBalance: double.parse(
                        balanceController.text.trim(),
                      ),
                      iconCodePoint: selectedIcon.codePoint,
                      colorValue: selectedColor.toARGB32(),
                    );
                    Navigator.of(context).pop();
                    _showMessage(message);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTransferDialog() async {
    if (_viewModel.accounts.length < 2) {
      _showMessage('Add at least two accounts to transfer funds.');
      return;
    }

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();
    String fromId = _viewModel.accounts.first.id;
    String toId = _viewModel.accounts[1].id;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Transfer Between Accounts'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: fromId,
                      decoration: const InputDecoration(labelText: 'From'),
                      items: _viewModel.accounts.map((FinanceAccount account) {
                        return DropdownMenuItem<String>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          fromId = value;
                          if (toId == fromId) {
                            final List<FinanceAccount> alternatives = _viewModel
                                .accounts
                                .where(
                                  (FinanceAccount account) =>
                                      account.id != fromId,
                                )
                                .toList();
                            toId = alternatives.first.id;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: toId,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: _viewModel.accounts
                          .where(
                            (FinanceAccount account) => account.id != fromId,
                          )
                          .map((FinanceAccount account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(account.name),
                            );
                          })
                          .toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          toId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (${_viewModel.selectedCurrency})',
                      ),
                      validator: (String? value) {
                        final double? parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final String message = _viewModel.transferBetweenAccounts(
                      fromAccountId: fromId,
                      toAccountId: toId,
                      amount: double.parse(amountController.text.trim()),
                    );
                    Navigator.of(context).pop();
                    _showMessage(message);
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showManageAccountsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final bool compactHeader =
                                constraints.maxWidth < 430;
                            if (!compactHeader) {
                              return Row(
                                children: <Widget>[
                                  Text(
                                    'Manage Accounts',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await _showTransferDialog();
                                      setModalState(() {});
                                    },
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('Transfer'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await _showAddAccountDialog();
                                      setModalState(() {});
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Manage Accounts',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    TextButton.icon(
                                      onPressed: () async {
                                        await _showTransferDialog();
                                        setModalState(() {});
                                      },
                                      icon: const Icon(Icons.swap_horiz),
                                      label: const Text('Transfer'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () async {
                                        await _showAddAccountDialog();
                                        setModalState(() {});
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _viewModel.accounts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final FinanceAccount account =
                              _viewModel.accounts[index];
                          final Color accountColor = Color(
                            account.colorValue ?? 0xFF0F766E,
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: accountColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Icon(
                                account.iconCodePoint == null
                                    ? Icons.account_balance_wallet_outlined
                                    : IconData(
                                        account.iconCodePoint!,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                color: accountColor,
                              ),
                            ),
                            title: Text(account.name),
                            subtitle: Text(_accountTypeLabel(account.type)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${_viewModel.currencySymbol}${account.balance.toStringAsFixed(2)}',
                                ),
                                IconButton(
                                  tooltip: 'Remove account',
                                  onPressed: () {
                                    final String message = _viewModel
                                        .removeFinanceAccount(account.id);
                                    _showMessage(message);
                                    setModalState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showManageCategoriesSheet() async {
    final TextEditingController controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> categories = _viewModel.customCategories.toList()
              ..sort();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Manage Categories',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'New Category',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            final String message = _viewModel.addCustomCategory(
                              controller.text,
                            );
                            _showMessage(message);
                            if (message == 'Category added.') {
                              controller.clear();
                              setModalState(() {});
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final String category = categories[index];
                          return ListTile(
                            leading: const Icon(Icons.label_outline),
                            title: Text(category),
                            trailing: IconButton(
                              tooltip: 'Delete category',
                              onPressed: () {
                                final String message = _viewModel
                                    .removeCustomCategory(category);
                                _showMessage(message);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCurrencyPicker() async {
    final List<String> currencies = _viewModel.exchangeRates.keys.toList()
      ..sort();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const ListTile(title: Text('Select Currency')),
              ...currencies.map((String code) {
                final bool selected = code == _viewModel.selectedCurrency;
                return ListTile(
                  title: Text(code),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    _viewModel.setCurrency(code);
                    Navigator.of(context).pop();
                    _showMessage('Currency changed to $code.');
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleAppLockToggle(bool enabled) {
    if (!enabled) {
      _viewModel.setAppLockEnabled(false);
      _showMessage('App lock disabled.');
      return;
    }

    unawaited(() async {
      final String? message = await _showSetPinDialog();
      if (message != null) {
        _showMessage(message);
      }
    }());
  }

  Future<String?> _showSetPinDialog() async {
    String? result;
    String pin = '';
    String confirmPin = '';
    bool editingConfirm = false;
    int confirmShakeTick = 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            void appendDigit(String digit) {
              bool shouldAutoEnable = false;
              setDialogState(() {
                if (editingConfirm) {
                  if (confirmPin.length < 4) {
                    confirmPin += digit;
                    shouldAutoEnable =
                        confirmPin.length == 4 && pin.length == 4;
                  }
                } else {
                  if (pin.length < 4) {
                    pin += digit;
                    if (pin.length == 4) {
                      editingConfirm = true;
                    }
                  }
                }
              });

              if (shouldAutoEnable && confirmPin == pin) {
                result = _viewModel.setAppLockPin(pin);
                Navigator.of(context).pop();
              } else if (shouldAutoEnable && confirmPin != pin) {
                setDialogState(() {
                  confirmShakeTick += 1;
                });
              }
            }

            void deleteDigit() {
              setDialogState(() {
                if (editingConfirm) {
                  if (confirmPin.isNotEmpty) {
                    confirmPin = confirmPin.substring(0, confirmPin.length - 1);
                  } else {
                    editingConfirm = false;
                  }
                } else if (pin.isNotEmpty) {
                  pin = pin.substring(0, pin.length - 1);
                }
              });
            }

            void clearActive() {
              setDialogState(() {
                if (editingConfirm) {
                  confirmPin = '';
                } else {
                  pin = '';
                }
              });
            }

            final bool mismatch = confirmPin.length == 4 && confirmPin != pin;

            return AlertDialog(
              title: const Text('Set 4-digit PIN'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    PinDots(
                      label: 'PIN',
                      length: pin.length,
                      maxLength: 4,
                      active: !editingConfirm,
                      onTap: () {
                        setDialogState(() {
                          editingConfirm = false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      key: ValueKey<int>(confirmShakeTick),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 320),
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            final double offset =
                                math.sin(value * math.pi * 4) *
                                10 *
                                (1 - value);
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                      child: PinDots(
                        label: 'Confirm PIN',
                        length: confirmPin.length,
                        maxLength: 4,
                        active: editingConfirm,
                        errorFlashTick: confirmShakeTick,
                        onTap: () {
                          setDialogState(() {
                            editingConfirm = true;
                          });
                        },
                      ),
                    ),
                    if (mismatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'PINs do not match',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 12),
                    PinPad(
                      onDigit: appendDigit,
                      onBackspace: deleteDigit,
                      onClear: clearActive,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    result = 'App lock setup cancelled.';
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  void _handleBiometricToggle(bool enabled) {
    unawaited(() async {
      final String message = await _viewModel.setBiometricEnabledWithValidation(
        enabled,
      );
      _showMessage(message);
    }());
  }

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runAsyncAction(Future<String> Function() action) async {
    final String message = await action();
    _showMessage(message);
  }

  Future<void> _showAddFixedDepositDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController bankController = TextEditingController();
    final TextEditingController accountController = TextEditingController();
    final TextEditingController principalController = TextEditingController();
    final TextEditingController rateController = TextEditingController();
    final TextEditingController reminderDaysController = TextEditingController(
      text: '7',
    );
    final TextEditingController notesController = TextEditingController();
    DateTime startDate = _viewModel.appDateTime;
    DateTime maturityDate = DateTime(
      startDate.year + 1,
      startDate.month,
      startDate.day,
    );
    bool reminderEnabled = true;

    Future<void> pickDate({
      required DateTime initialDate,
      required ValueChanged<DateTime> onPicked,
    }) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        onPicked(picked);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Fixed Deposit'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: bankController,
                        decoration: const InputDecoration(
                          labelText: 'Bank / Institution',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter bank name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: accountController,
                        decoration: const InputDecoration(
                          labelText: 'FD number (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: principalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Principal (${_viewModel.selectedCurrency})',
                        ),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid principal';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Annual interest rate (%)',
                        ),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid rate';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available),
                        title: const Text('Start Date'),
                        subtitle: Text(
                          '${startDate.day}/${startDate.month}/${startDate.year}',
                        ),
                        onTap: () async {
                          await pickDate(
                            initialDate: startDate,
                            onPicked: (DateTime picked) {
                              setDialogState(() {
                                startDate = picked;
                                if (!maturityDate.isAfter(startDate)) {
                                  maturityDate = DateTime(
                                    startDate.year + 1,
                                    startDate.month,
                                    startDate.day,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('Maturity Date'),
                        subtitle: Text(
                          '${maturityDate.day}/${maturityDate.month}/${maturityDate.year}',
                        ),
                        onTap: () async {
                          await pickDate(
                            initialDate: maturityDate,
                            onPicked: (DateTime picked) {
                              setDialogState(() {
                                maturityDate = picked;
                              });
                            },
                          );
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: reminderEnabled,
                        onChanged: (bool value) {
                          setDialogState(() {
                            reminderEnabled = value;
                          });
                        },
                        title: const Text('Reminder'),
                        subtitle: const Text('Notify before maturity'),
                        secondary: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                      ),
                      if (reminderEnabled) ...<Widget>[
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: reminderDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reminder days before maturity',
                          ),
                          validator: (String? value) {
                            if (!reminderEnabled) {
                              return null;
                            }
                            final int? parsed = int.tryParse(value ?? '');
                            if (parsed == null || parsed < 0) {
                              return 'Enter valid days';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: notesController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final int reminderDays =
                        int.tryParse(reminderDaysController.text.trim()) ?? 0;
                    final String message = _viewModel.addFixedDeposit(
                      bankName: bankController.text,
                      accountNumber: accountController.text,
                      principal: double.parse(principalController.text.trim()),
                      interestRate: double.parse(rateController.text.trim()),
                      startDate: startDate,
                      maturityDate: maturityDate,
                      reminderDate: maturityDate.subtract(
                        Duration(days: reminderDays),
                      ),
                      reminderEnabled: reminderEnabled,
                      notes: notesController.text,
                    );
                    Navigator.of(context).pop();
                    _showMessage(message);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    bankController.dispose();
    accountController.dispose();
    principalController.dispose();
    rateController.dispose();
    reminderDaysController.dispose();
    notesController.dispose();
  }

  void _closeFixedDeposit(String id) {
    final String message = _viewModel.closeFixedDeposit(id);
    _showMessage(message);
  }

  void _deleteFixedDeposit(String id) {
    final String message = _viewModel.removeFixedDeposit(id);
    _showMessage(message);
  }

  Future<void> _showEditProfileDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: _viewModel.userName,
    );
    final TextEditingController emailController = TextEditingController(
      text: _viewModel.userEmail,
    );
    final TextEditingController imageUrlController = TextEditingController(
      text: _viewModel.userProfileImageUrl,
    );
    String previewImageData = _viewModel.userProfileImageUrl;

    Future<void> pickImage(
      ImageSource source,
      StateSetter setDialogState,
    ) async {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) {
        return;
      }
      final List<int> bytes = await picked.readAsBytes();
      final String encoded = base64Encode(bytes);
      setDialogState(() {
        previewImageData = encoded;
        imageUrlController.text = encoded;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final bool hasPreview = previewImageData.trim().isNotEmpty;
            final bool isPreviewNetwork =
                previewImageData.startsWith('http://') ||
                previewImageData.startsWith('https://');

            ImageProvider<Object>? previewImage;
            if (hasPreview && isPreviewNetwork) {
              previewImage = NetworkImage(previewImageData);
            } else if (hasPreview) {
              try {
                previewImage = MemoryImage(base64Decode(previewImageData));
              } catch (_) {
                previewImage = null;
              }
            }

            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 30,
                      foregroundImage: previewImage,
                      child: hasPreview ? null : const Icon(Icons.person),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                pickImage(ImageSource.gallery, setDialogState),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                pickImage(ImageSource.camera, setDialogState),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (String? value) {
                        final String text = value?.trim() ?? '';
                        if (text.isEmpty || !text.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      _viewModel.updateProfile(
                        name: nameController.text,
                        email: emailController.text,
                        profileImageUrl: imageUrlController.text,
                      );
                      Navigator.of(context).pop();
                      _showMessage('Profile updated successfully.');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController oldController = TextEditingController();
    final TextEditingController newController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: oldController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter new password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm new password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final String message = _viewModel.changePassword(
                    oldPassword: oldController.text,
                    newPassword: newController.text,
                    confirmPassword: confirmController.text,
                  );
                  Navigator.of(context).pop();
                  _showMessage(message);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAdjustDateTimeDialog() async {
    DateTime selectedDateTime = _viewModel.appDateTime;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Adjust App Date & Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} '
                    '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: selectedDateTime,
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  selectedDateTime.hour,
                                  selectedDateTime.minute,
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Date'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                selectedDateTime,
                              ),
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime.year,
                                  selectedDateTime.month,
                                  selectedDateTime.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: const Text('Time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    _viewModel.adjustAppDateTime(selectedDateTime);
                    Navigator.of(context).pop();
                    _showMessage('App date and time updated.');
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showResetAppDialog() async {
    final BuildContext pageContext = context;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset App'),
          content: const Text(
            'This will reset profile, budget, goals, entries, and app date/time to defaults. Continue?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!mounted) {
                  return;
                }

                unawaited(
                  showDialog<void>(
                    context: pageContext,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Resetting App...'),
                        content: SizedBox(
                          width: 320,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Please wait while we reset your app data.',
                              ),
                              const SizedBox(height: 14),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(seconds: 3),
                                builder:
                                    (
                                      BuildContext context,
                                      double value,
                                      Widget? child,
                                    ) {
                                      return LinearProgressIndicator(
                                        value: value,
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );

                final String message = await _viewModel.resetApp();
                await Future<void>.delayed(const Duration(seconds: 3));

                if (mounted) {
                  Navigator.of(pageContext, rootNavigator: true).pop();
                  _showMessage(message);
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final BuildContext pageContext = context;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This will permanently delete your account profile and all finance data on this device. Continue?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!mounted) {
                  return;
                }
                unawaited(
                  showDialog<void>(
                    context: pageContext,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Deleting Account...'),
                        content: SizedBox(
                          width: 320,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Please wait while we clear your data.',
                              ),
                              const SizedBox(height: 14),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(seconds: 6),
                                builder:
                                    (
                                      BuildContext context,
                                      double value,
                                      Widget? child,
                                    ) {
                                      return LinearProgressIndicator(
                                        value: value,
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );

                await Future.wait(<Future<void>>[
                  _viewModel.deleteAccount().then((String _) {}),
                  Future<void>.delayed(const Duration(seconds: 6)),
                ]);

                if (mounted) {
                  Navigator.of(pageContext, rootNavigator: true).pop();
                  widget.onLogout();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTransactionDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final List<String> categories = _viewModel.customCategories.toList()
      ..sort();
    String category = categories.isNotEmpty ? categories.first : 'Food';
    TransactionType type = TransactionType.expense;
    bool isSplit = false;
    final List<TextEditingController> splitAmountControllers =
        <TextEditingController>[];
    final List<String> splitCategories = <String>[];

    void addSplitPart() {
      splitAmountControllers.add(TextEditingController());
      splitCategories.add(category);
    }

    addSplitPart();
    DateTime selectedDate = DateTime.now();
    String? selectedAccountId;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TransactionType>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const <DropdownMenuItem<TransactionType>>[
                          DropdownMenuItem<TransactionType>(
                            value: TransactionType.expense,
                            child: Text('Expense'),
                          ),
                          DropdownMenuItem<TransactionType>(
                            value: TransactionType.income,
                            child: Text('Income'),
                          ),
                        ],
                        onChanged: (TransactionType? value) {
                          if (value != null) {
                            setDialogState(() {
                              type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isSplit,
                        title: const Text('Split Transaction'),
                        subtitle: const Text(
                          'Split this purchase into multiple categories',
                        ),
                        onChanged: (bool value) {
                          setDialogState(() {
                            isSplit = value;
                          });
                        },
                      ),
                      if (isSplit) ...<Widget>[
                        const SizedBox(height: 8),
                        ...List<Widget>.generate(splitCategories.length, (
                          int index,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: splitCategories[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Split Category',
                                    ),
                                    items: categories
                                        .map(
                                          (String item) =>
                                              DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(item),
                                              ),
                                        )
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setDialogState(() {
                                        splitCategories[index] = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    controller: splitAmountControllers[index],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                    ),
                                  ),
                                ),
                                if (splitCategories.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        splitAmountControllers.removeAt(index);
                                        splitCategories.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(addSplitPart);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Split Part'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedAccountId,
                        decoration: const InputDecoration(labelText: 'Account'),
                        items: _viewModel.accounts
                            .map(
                              (FinanceAccount account) =>
                                  DropdownMenuItem<String>(
                                    value: account.id,
                                    child: Text(account.name),
                                  ),
                            )
                            .toList(),
                        onChanged: _viewModel.accounts.isEmpty
                            ? null
                            : (String? value) {
                                setDialogState(() {
                                  selectedAccountId = value;
                                });
                              },
                        validator: (String? value) {
                          if (_viewModel.accounts.isEmpty) {
                            return 'Add an account first';
                          }
                          if (value == null) {
                            return 'Select an account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final DateTime? date = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: selectedDate,
                              );
                              if (date != null) {
                                setDialogState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_month),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      if (isSplit) {
                        final List<TransactionSplitPart> parts =
                            <TransactionSplitPart>[];
                        for (int i = 0; i < splitCategories.length; i++) {
                          final double? amount = double.tryParse(
                            splitAmountControllers[i].text.trim(),
                          );
                          if (amount == null || amount <= 0) {
                            _showMessage('Enter valid split amounts.');
                            return;
                          }
                          parts.add(
                            TransactionSplitPart(
                              category: splitCategories[i],
                              amount: amount,
                            ),
                          );
                        }
                        _viewModel.addSplitTransaction(
                          title: titleController.text.trim(),
                          date: selectedDate,
                          type: type,
                          accountId: selectedAccountId,
                          parts: parts,
                        );
                      } else {
                        _viewModel.addTransaction(
                          TransactionEntry(
                            title: titleController.text.trim(),
                            category: category,
                            amount: double.parse(amountController.text.trim()),
                            date: selectedDate,
                            type: type,
                            accountId: selectedAccountId,
                          ),
                        );
                      }
                      final List<String> alerts = _viewModel.budgetAlerts();
                      if (alerts.isNotEmpty) {
                        _showMessage(alerts.first);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBudgetDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _viewModel.monthlyBudget.toStringAsFixed(0),
    );
    final Set<String> categories = <String>{
      ..._viewModel.customCategories,
      ..._viewModel.categoryBudgets.keys,
      ..._viewModel.weeklyCategoryBudgets.keys,
      ..._viewModel.dailyCategoryBudgets.keys,
    };
    final List<String> categoryList = categories.toList()..sort();
    BudgetPeriod selectedPeriod = BudgetPeriod.monthly;
    bool applyToOverallMonthly = true;
    String selectedCategory = categoryList.isNotEmpty
        ? categoryList.first
        : 'General';

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Budget'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<BudgetPeriod>(
                      initialValue: selectedPeriod,
                      decoration: const InputDecoration(labelText: 'Period'),
                      items: const <DropdownMenuItem<BudgetPeriod>>[
                        DropdownMenuItem<BudgetPeriod>(
                          value: BudgetPeriod.daily,
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem<BudgetPeriod>(
                          value: BudgetPeriod.weekly,
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem<BudgetPeriod>(
                          value: BudgetPeriod.monthly,
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (BudgetPeriod? value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPeriod = value;
                            if (selectedPeriod != BudgetPeriod.monthly) {
                              applyToOverallMonthly = false;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedPeriod == BudgetPeriod.monthly)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Apply as overall monthly limit'),
                        value: applyToOverallMonthly,
                        onChanged: (bool value) {
                          setDialogState(() {
                            applyToOverallMonthly = value;
                          });
                        },
                      ),
                    if (selectedPeriod != BudgetPeriod.monthly ||
                        !applyToOverallMonthly)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Expense Category',
                        ),
                        items: categoryList
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final double? value = double.tryParse(
                      controller.text.trim(),
                    );
                    if (value == null || value <= 0) {
                      return;
                    }

                    if (selectedPeriod == BudgetPeriod.monthly &&
                        applyToOverallMonthly) {
                      _viewModel.setBudget(value);
                    } else {
                      _viewModel.setCategoryBudget(
                        category: selectedCategory,
                        value: value,
                        period: selectedPeriod,
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddGoalDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController targetController = TextEditingController();
    final TextEditingController currentController = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 90));

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Savings Goal'),
              content: SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Name',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter goal name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                        ),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid target';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: currentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Current Saved',
                        ),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Deadline: ${deadline.day}/${deadline.month}/${deadline.year}',
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final DateTime? date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                initialDate: deadline,
                              );
                              if (date != null) {
                                setDialogState(() {
                                  deadline = date;
                                });
                              }
                            },
                            icon: const Icon(Icons.flag),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      _viewModel.addGoal(
                        SavingsGoal(
                          name: nameController.text.trim(),
                          targetAmount: double.parse(
                            targetController.text.trim(),
                          ),
                          currentAmount: double.parse(
                            currentController.text.trim(),
                          ),
                          deadline: deadline,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSendCashToGoalDialog(int goalIndex) async {
    if (goalIndex < 0 || goalIndex >= _viewModel.goals.length) {
      _showMessage('Selected goal not found.');
      return;
    }

    final List<FinanceAccount> sourceAccounts = _viewModel.accounts
        .where((FinanceAccount account) => !account.isLiability)
        .toList();
    if (sourceAccounts.isEmpty) {
      _showMessage('No eligible accounts available for goal funding.');
      return;
    }

    final TextEditingController amountController = TextEditingController();
    String selectedAccountId = sourceAccounts.first.id;
    final SavingsGoal goal = _viewModel.goals[goalIndex];

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Send Cash to ${goal.name}'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'From Account',
                      ),
                      items: sourceAccounts.map((FinanceAccount account) {
                        return DropdownMenuItem<String>(
                          value: account.id,
                          child: Text(
                            '${account.name} (${_viewModel.currencySymbol}${account.balance.toStringAsFixed(2)})',
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedAccountId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount (${_viewModel.selectedCurrency})',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final double? amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      _showMessage('Enter a valid amount.');
                      return;
                    }
                    final String message = _viewModel.sendCashToGoal(
                      goalIndex: goalIndex,
                      fromAccountId: selectedAccountId,
                      amount: amount,
                    );
                    Navigator.of(context).pop();
                    _showMessage(message);
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteGoal(int goalIndex) async {
    if (goalIndex < 0 || goalIndex >= _viewModel.goals.length) {
      _showMessage('Selected goal not found.');
      return;
    }
    final String goalName = _viewModel.goals[goalIndex].name;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: Text('Delete "$goalName" goal?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String message = _viewModel.removeGoalAt(goalIndex);
    _showMessage(message);
  }

  Future<void> _showReportSummaryDialog() async {
    String selectedPeriod = 'Month';
    DateTime anchor = _viewModel.appDateTime;

    DateTime rangeStart(String period) {
      switch (period) {
        case 'Day':
          return DateTime(anchor.year, anchor.month, anchor.day);
        case 'Week':
          final DateTime day = DateTime(anchor.year, anchor.month, anchor.day);
          return day.subtract(Duration(days: day.weekday - 1));
        default:
          return DateTime(anchor.year, anchor.month, 1);
      }
    }

    DateTime rangeEndExclusive(String period) {
      switch (period) {
        case 'Day':
          return DateTime(
            anchor.year,
            anchor.month,
            anchor.day,
          ).add(const Duration(days: 1));
        case 'Week':
          final DateTime start = rangeStart(period);
          return start.add(const Duration(days: 7));
        default:
          return DateTime(anchor.year, anchor.month + 1, 1);
      }
    }

    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    String periodLabel(String period) {
      switch (period) {
        case 'Day':
          return 'Selected Date';
        case 'Week':
          return 'Week Anchor Date';
        default:
          return 'Month Anchor Date';
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final DateTime start = rangeStart(selectedPeriod);
            final DateTime endExclusive = rangeEndExclusive(selectedPeriod);

            final List<TransactionEntry> filtered = _viewModel.transactions
                .where((TransactionEntry tx) {
                  final DateTime d = tx.date;
                  return !d.isBefore(start) && d.isBefore(endExclusive);
                })
                .toList();

            final double income = filtered
                .where(
                  (TransactionEntry tx) => tx.type == TransactionType.income,
                )
                .fold(0, (double sum, TransactionEntry tx) => sum + tx.amount);
            final double expense = filtered
                .where(
                  (TransactionEntry tx) => tx.type == TransactionType.expense,
                )
                .fold(0, (double sum, TransactionEntry tx) => sum + tx.amount);
            final double net = income - expense;

            final Map<String, double> byCategory = <String, double>{};
            for (final TransactionEntry tx in filtered) {
              if (tx.type != TransactionType.expense) {
                continue;
              }
              byCategory[tx.category] =
                  (byCategory[tx.category] ?? 0) + tx.amount;
            }

            final List<MapEntry<String, double>> topCategories =
                byCategory.entries.toList()..sort(
                  (MapEntry<String, double> a, MapEntry<String, double> b) =>
                      b.value.compareTo(a.value),
                );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Report Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _reportPeriods.map((String period) {
                        return ChoiceChip(
                          label: Text(period),
                          selected: selectedPeriod == period,
                          onSelected: (_) {
                            setModalState(() {
                              selectedPeriod = period;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: anchor,
                        );
                        if (picked == null) {
                          return;
                        }
                        setModalState(() {
                          anchor = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            anchor.hour,
                            anchor.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${periodLabel(selectedPeriod)}: ${formatDate(anchor)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Range: ${formatDate(start)} - ${formatDate(endExclusive.subtract(const Duration(days: 1)))}',
                    ),
                    const SizedBox(height: 8),
                    Text('Transactions: ${filtered.length}'),
                    Text(
                      'Income: ${_viewModel.currencySymbol}${income.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Expense: ${_viewModel.currencySymbol}${expense.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Net: ${_viewModel.currencySymbol}${net.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: net >= 0
                            ? const Color(0xFF0E9F6E)
                            : const Color(0xFFD64545),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Top 3 Expense Categories',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    if (topCategories.isEmpty)
                      const Text('No expense categories yet')
                    else
                      ...topCategories.take(3).toList().asMap().entries.map((
                        MapEntry<int, MapEntry<String, double>> entry,
                      ) {
                        final int rank = entry.key + 1;
                        final MapEntry<String, double> item = entry.value;
                        return Text(
                          '$rank. ${item.key} - ${_viewModel.currencySymbol}${item.value.toStringAsFixed(2)}',
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSavingsAutomationDialog() async {
    bool enabled = _viewModel.savingsAutomationEnabled;
    double percent = _viewModel.savingsAutomationPercent;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Savings Automation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: enabled,
                    onChanged: (bool value) {
                      setStateDialog(() {
                        enabled = value;
                      });
                    },
                    title: const Text('Enable automation'),
                    subtitle: const Text('Move % of income to first goal'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Text('Percent'),
                      Expanded(
                        child: Slider(
                          value: percent,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${percent.toStringAsFixed(0)}%',
                          onChanged: enabled
                              ? (double value) {
                                  setStateDialog(() {
                                    percent = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    _viewModel.setSavingsAutomation(
                      enabled: enabled,
                      percent: percent,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSubscriptionCenter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Subscription Center',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            final TextEditingController name =
                                TextEditingController();
                            final TextEditingController amount =
                                TextEditingController();
                            DateTime renewal = DateTime.now().add(
                              const Duration(days: 30),
                            );
                            await showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                  builder:
                                      (
                                        BuildContext context,
                                        StateSetter setAddState,
                                      ) {
                                        return AlertDialog(
                                          title: const Text('Add Subscription'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              TextField(
                                                controller: name,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Name',
                                                    ),
                                              ),
                                              TextField(
                                                controller: amount,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Amount',
                                                    ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  final DateTime?
                                                  date = await showDatePicker(
                                                    context: context,
                                                    firstDate: DateTime.now(),
                                                    lastDate: DateTime(2100),
                                                    initialDate: renewal,
                                                  );
                                                  if (date != null) {
                                                    setAddState(() {
                                                      renewal = date;
                                                    });
                                                  }
                                                },
                                                icon: const Icon(Icons.event),
                                                label: Text(
                                                  'Renewal: ${renewal.day}/${renewal.month}/${renewal.year}',
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                final double? value =
                                                    double.tryParse(
                                                      amount.text.trim(),
                                                    );
                                                if (name.text.trim().isEmpty ||
                                                    value == null ||
                                                    value <= 0) {
                                                  return;
                                                }
                                                _viewModel.addSubscription(
                                                  name: name.text,
                                                  amount: value,
                                                  renewalDate: renewal,
                                                );
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Add'),
                                            ),
                                          ],
                                        );
                                      },
                                );
                              },
                            );
                            setStateDialog(() {});
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _viewModel.subscriptions.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SubscriptionPlan sub =
                              _viewModel.subscriptions[index];
                          final int daysToRenewal = sub.daysToRenewal(
                            _viewModel.appDateTime,
                          );
                          final String dueText = daysToRenewal <= 0
                              ? 'Due today'
                              : daysToRenewal == 1
                              ? 'Due tomorrow'
                              : 'Due in $daysToRenewal days';
                          return ListTile(
                            title: Text(sub.name),
                            subtitle: Text(
                              'Renews ${sub.renewalDate.day}/${sub.renewalDate.month}/${sub.renewalDate.year} - $dueText',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Switch(
                                  value: sub.active,
                                  onChanged: (bool value) {
                                    _viewModel.toggleSubscriptionActive(
                                      sub.id,
                                      value,
                                    );
                                    setStateDialog(() {});
                                  },
                                ),
                                IconButton(
                                  onPressed: () {
                                    _viewModel.removeSubscription(sub.id);
                                    setStateDialog(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDashboardWidgetManager() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Customize Dashboard Widgets',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ReorderableListView(
                        shrinkWrap: true,
                        onReorder: (int oldIndex, int newIndex) {
                          _viewModel.reorderDashboardWidgets(
                            oldIndex,
                            newIndex,
                          );
                          setStateDialog(() {});
                        },
                        children: _viewModel.dashboardWidgetOrder.map((
                          DashboardWidgetId id,
                        ) {
                          final bool visible = !_viewModel
                              .hiddenDashboardWidgets
                              .contains(id);
                          return SwitchListTile(
                            key: ValueKey<String>(id.name),
                            value: visible,
                            onChanged: (bool value) {
                              _viewModel.setDashboardWidgetVisible(id, value);
                              setStateDialog(() {});
                            },
                            title: Text(id.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAppearanceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Appearance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    value: _viewModel.darkModeEnabled,
                    onChanged: (bool value) {
                      _viewModel.setDarkModeEnabled(value);
                      setStateDialog(() {});
                    },
                  ),
                  DropdownButtonFormField<AppThemePreset>(
                    initialValue: _viewModel.themePreset,
                    decoration: const InputDecoration(
                      labelText: 'Theme Preset',
                    ),
                    items: AppThemePreset.values
                        .map(
                          (AppThemePreset preset) =>
                              DropdownMenuItem<AppThemePreset>(
                                value: preset,
                                child: Text(preset.name),
                              ),
                        )
                        .toList(),
                    onChanged: (AppThemePreset? value) {
                      if (value == null) {
                        return;
                      }
                      _viewModel.setThemePreset(value);
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (BuildContext context, Widget? child) {
        final Map<String, double> goalSavedByAccount = <String, double>{
          for (final FinanceAccount account in _viewModel.accounts)
            account.id: _viewModel.goalsSavedByAccount(account.id),
        };
        final Map<String, List<({String goalName, double amount})>>
        goalSavingsBreakdownByAccount =
            <String, List<({String goalName, double amount})>>{
              for (final FinanceAccount account in _viewModel.accounts)
                account.id: _viewModel.goalSavingsBreakdownByAccount(
                  account.id,
                ),
            };

        final List<Widget> screens = <Widget>[
          DashboardScreen(
            balance: _viewModel.totalAccountBalance,
            income: _viewModel.totalIncome,
            expense: _viewModel.totalExpense,
            budgetUsage: _viewModel.budgetUsage,
            monthlyBudget: _viewModel.monthlyBudget,
            topCategories: _viewModel.expenseByCategory,
            weeklyExpenses: _viewModel.last30DayExpenses,
            netWorth: _viewModel.netWorth,
            endOfMonthForecast: _viewModel.endOfMonthForecastBalance,
            budgetScore: _viewModel.budgetAdherenceScore,
            savingsStreakWeeks: _viewModel.savingsStreakWeeks,
            personalizedTips: _viewModel.personalizedTips,
            currencySymbol: _viewModel.currencySymbol,
            accountBalanceBreakdown: _viewModel.currentBalanceAccountBreakdown,
            goalSavedByAccount: goalSavedByAccount,
            goalSavingsBreakdownByAccount: goalSavingsBreakdownByAccount,
            selectedBudgetHealthGoalName:
                _viewModel.selectedBudgetHealthGoal?.name,
            selectedBudgetHealthGoalProgress:
                _viewModel.selectedBudgetHealthGoal?.progress,
            selectedBudgetHealthGoalSaved:
                _viewModel.selectedBudgetHealthGoal?.currentAmount,
            selectedBudgetHealthGoalTarget:
                _viewModel.selectedBudgetHealthGoal?.targetAmount,
            visibleWidgetIds: _viewModel.visibleDashboardWidgets,
          ),
          TransactionsScreen(
            transactions: _viewModel.transactions,
            currencySymbol: _viewModel.currencySymbol,
          ),
          BudgetPlannerScreen(
            categoryBudgets: _viewModel.categoryBudgets,
            dailyCategoryBudgets: _viewModel.dailyCategoryBudgets,
            weeklyCategoryBudgets: _viewModel.weeklyCategoryBudgets,
            categoryExpenses: _viewModel.expenseByCategory,
            dailyCategoryExpenses: _viewModel.dailyExpenseByCategory,
            weeklyCategoryExpenses: _viewModel.weeklyExpenseByCategory,
            currencySymbol: _viewModel.currencySymbol,
          ),
          GoalsScreen(
            goals: _viewModel.goals,
            currencySymbol: _viewModel.currencySymbol,
            selectedHomeGoalName: _viewModel.selectedBudgetHealthGoal?.name,
            onSendCashToGoal: _showSendCashToGoalDialog,
            onDeleteGoal: _confirmDeleteGoal,
            onSelectHomeGoal: _viewModel.setBudgetHealthGoalName,
          ),
          FdManageScreen(
            fixedDeposits: _viewModel.fixedDeposits,
            currencySymbol: _viewModel.currencySymbol,
            now: _viewModel.appDateTime,
            totalPrincipal: _viewModel.fixedDepositPrincipal,
            totalExpectedInterest: _viewModel.fixedDepositExpectedInterest,
            onToggleReminder: _viewModel.toggleFixedDepositReminder,
            onCloseDeposit: _closeFixedDeposit,
            onDeleteDeposit: _deleteFixedDeposit,
          ),
          ReportsScreen(
            income: _viewModel.totalIncome,
            expense: _viewModel.totalExpense,
            dateTrendData: _viewModel.dailyExpenseByCategory,
            weekTrendData: _viewModel.spendingTrendByCategory(TrendWindow.week),
            monthTrendData: _viewModel.spendingTrendByCategory(
              TrendWindow.month,
            ),
            netWorth: _viewModel.netWorth,
            endOfMonthForecast: _viewModel.endOfMonthForecastBalance,
            goalInsights: _viewModel.goalInsights,
            smartBillAlerts: _viewModel.smartBillAlerts,
            currencySymbol: _viewModel.currencySymbol,
          ),
          SettingsScreen(
            userName: _viewModel.userName,
            userEmail: _viewModel.userEmail,
            userProfileImageUrl: _viewModel.userProfileImageUrl,
            appDateTime: _viewModel.appDateTime,
            onEditProfile: _showEditProfileDialog,
            onChangePassword: _showChangePasswordDialog,
            onManageAccounts: _showManageAccountsSheet,
            onManageCategories: _showManageCategoriesSheet,
            onAdjustDateTime: _showAdjustDateTimeDialog,
            onResetApp: _showResetAppDialog,
            onDeleteAccount: _showDeleteAccountDialog,
            onLogout: widget.onLogout,
            selectedCurrency: _viewModel.selectedCurrency,
            onSelectCurrency: _showCurrencyPicker,
            includeLiabilitiesInCurrentBalance:
                _viewModel.includeLiabilitiesInCurrentBalance,
            onToggleIncludeLiabilities:
                _viewModel.setIncludeLiabilitiesInCurrentBalance,
            appLockEnabled: _viewModel.appLockEnabled,
            biometricEnabled: _viewModel.biometricEnabled,
            onToggleAppLock: _handleAppLockToggle,
            onToggleBiometric: _handleBiometricToggle,
            financialSnapshot: _viewModel.financialHealthSnapshot,
            categoryCount: _viewModel.customCategories.length,
            reminderEnabled: _viewModel.reminderEnabled,
            onToggleReminder: (bool enabled) {
              if (enabled != _viewModel.reminderEnabled) {
                _runAsyncAction(_viewModel.toggleReminder);
              }
            },
            onManageSavingsAutomation: _showSavingsAutomationDialog,
            onOpenSubscriptionCenter: _showSubscriptionCenter,
            onOpenDashboardWidgets: _showDashboardWidgetManager,
            onOpenAppearance: _showAppearanceDialog,
          ),
        ];

        return AnimatedTheme(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          data: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _viewModel.themeSeedColor,
              brightness: _viewModel.darkModeEnabled
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Expenso',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Welcome ${_viewModel.userName}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            body: Stack(
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        final Animation<Offset> slide =
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_viewModel.selectedIndex),
                    child: screens[_viewModel.selectedIndex],
                  ),
                ),
                if (_isPageSwitching) _buildPageSwitchLoadingOverlay(context),
              ],
            ),
            floatingActionButton: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final Animation<double> scale = Tween<double>(
                  begin: 0.92,
                  end: 1,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: switch (_viewModel.selectedIndex) {
                2 => FloatingActionButton.extended(
                  key: const ValueKey<String>('fab-budget'),
                  onPressed: _showBudgetDialog,
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Add Budget'),
                ),
                3 => FloatingActionButton.extended(
                  key: const ValueKey<String>('fab-goal'),
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.savings),
                  label: const Text('Add Goal'),
                ),
                4 => FloatingActionButton.extended(
                  key: const ValueKey<String>('fab-fd'),
                  onPressed: _showAddFixedDepositDialog,
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Add FD'),
                ),
                5 => FloatingActionButton.extended(
                  key: const ValueKey<String>('fab-report'),
                  onPressed: _showReportSummaryDialog,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Report'),
                ),
                6 => const SizedBox.shrink(key: ValueKey<String>('fab-none')),
                _ => FloatingActionButton.extended(
                  key: const ValueKey<String>('fab-entry'),
                  onPressed: _showAddTransactionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              },
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _viewModel.selectedIndex,
              onDestinationSelected: _handlePageChange,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long),
                  label: 'Entries',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart),
                  label: 'Budget',
                ),
                NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
                NavigationDestination(
                  icon: Icon(Icons.account_balance),
                  label: 'FD',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
