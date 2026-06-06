import 'package:flutter/material.dart';

class FinanceCard extends StatelessWidget {
  const FinanceCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.currencySymbol,
    this.onTap,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String currencySymbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$currencySymbol${value.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniFinanceCard extends StatelessWidget {
  const MiniFinanceCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.currencySymbol,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color tone;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: tone),
            const SizedBox(height: 6),
            Text(label),
            Text(
              '$currencySymbol${value.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
