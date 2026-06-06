import 'package:flutter/material.dart';

import '../../models/finance_feature_models.dart';

class FdManageScreen extends StatelessWidget {
  const FdManageScreen({
    super.key,
    required this.fixedDeposits,
    required this.currencySymbol,
    required this.now,
    required this.totalPrincipal,
    required this.totalExpectedInterest,
    required this.onToggleReminder,
    required this.onCloseDeposit,
    required this.onDeleteDeposit,
  });

  final List<FixedDeposit> fixedDeposits;
  final String currencySymbol;
  final DateTime now;
  final double totalPrincipal;
  final double totalExpectedInterest;
  final void Function(String id, bool enabled) onToggleReminder;
  final ValueChanged<String> onCloseDeposit;
  final ValueChanged<String> onDeleteDeposit;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(BuildContext context, FixedDeposit fd) {
    if (fd.isClosed) {
      return Theme.of(context).colorScheme.outline;
    }
    if (fd.isMatured(now)) {
      return const Color(0xFFD64545);
    }
    if (fd.daysToMaturity(now) <= 30) {
      return const Color(0xFFB45309);
    }
    return const Color(0xFF0E9F6E);
  }

  String _statusLabel(FixedDeposit fd) {
    if (fd.isClosed) {
      return 'Closed';
    }
    final int days = fd.daysToMaturity(now);
    if (days <= 0) {
      return 'Matured';
    }
    if (days == 1) {
      return '1 day left';
    }
    return '$days days left';
  }

  Widget _summaryCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double maturityTotal = totalPrincipal + totalExpectedInterest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'FD Portfolio',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MetricTile(
                    label: 'Principal',
                    value:
                        '$currencySymbol${totalPrincipal.toStringAsFixed(0)}',
                    icon: Icons.account_balance,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Interest',
                    value:
                        '$currencySymbol${totalExpectedInterest.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: const Color(0xFF0E9F6E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetricTile(
              label: 'Expected Maturity Value',
              value: '$currencySymbol${maturityTotal.toStringAsFixed(0)}',
              icon: Icons.savings_outlined,
              color: const Color(0xFF1E429F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.account_balance_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No fixed deposits yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Add an FD to track maturity value and reminders.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositCard(BuildContext context, FixedDeposit fd) {
    final Color statusColor = _statusColor(context, fd);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.account_balance, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        fd.bankName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if ((fd.accountNumber ?? '').isNotEmpty)
                        Text(
                          fd.accountNumber!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(fd),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _InfoChip(
                  label: 'Principal',
                  value: '$currencySymbol${fd.principal.toStringAsFixed(0)}',
                ),
                _InfoChip(
                  label: 'Rate',
                  value: '${fd.interestRate.toStringAsFixed(2)}%',
                ),
                _InfoChip(
                  label: 'Maturity',
                  value: _formatDate(fd.maturityDate),
                ),
                _InfoChip(
                  label: 'Value',
                  value:
                      '$currencySymbol${fd.maturityAmount.toStringAsFixed(0)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: fd.reminderEnabled,
              onChanged: fd.isClosed
                  ? null
                  : (bool value) => onToggleReminder(fd.id, value),
              title: const Text('Reminder'),
              subtitle: Text('Alert from ${_formatDate(fd.reminderDate)}'),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            Row(
              children: <Widget>[
                if (!fd.isClosed)
                  TextButton.icon(
                    onPressed: () => onCloseDeposit(fd.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Close'),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete FD',
                  onPressed: () => onDeleteDeposit(fd.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fixedDeposits.isEmpty) {
      return _emptyState(context);
    }

    final List<FixedDeposit> sorted = fixedDeposits.toList()
      ..sort((FixedDeposit a, FixedDeposit b) {
        if (a.isClosed != b.isClosed) {
          return a.isClosed ? 1 : -1;
        }
        return a.maturityDate.compareTo(b.maturityDate);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length + 1,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _summaryCard(context);
        }
        return _buildDepositCard(context, sorted[index - 1]);
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
