import 'package:flutter/material.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.maxLength,
    required this.label,
    this.active = false,
    this.onTap,
    this.errorFlashTick = 0,
  });

  final int length;
  final int maxLength;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final int errorFlashTick;

  @override
  Widget build(BuildContext context) {
    final Color stroke = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    final bool flash = errorFlashTick > 0;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(errorFlashTick),
      tween: Tween<double>(begin: flash ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 320),
      builder: (BuildContext context, double value, Widget? child) {
        final Color animatedStroke = Color.lerp(
          const Color(0xFFD64545),
          stroke,
          value,
        )!;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(maxLength, (int index) {
                  final bool filled = index < length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? animatedStroke : Colors.transparent,
                        border: Border.all(color: animatedStroke, width: 1.2),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const List<List<String>> rows = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double minSize = 56;
        const double maxSize = 78;
        const double hGap = 10;
        const double vGap = 10;

        final double available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320;
        final double computed = (available - (hGap * 2)) / 3;
        final double buttonSize = computed.clamp(minSize, maxSize);
        final double actionSize = (buttonSize * 0.56).clamp(40, 48);

        return Column(
          children: <Widget>[
            for (final List<String> row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: vGap),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((String digit) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: hGap / 2),
                      child: _PinButton(
                        label: digit,
                        size: buttonSize,
                        onPressed: () => onDigit(digit),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _PinSmallActionButton(
                    icon: Icons.close,
                    tooltip: 'Clear',
                    size: actionSize,
                    onPressed: onClear,
                  ),
                  SizedBox(width: hGap + 6),
                  _PinButton(
                    label: '0',
                    size: buttonSize,
                    onPressed: () => onDigit('0'),
                  ),
                  SizedBox(width: hGap + 6),
                  _PinSmallActionButton(
                    icon: Icons.backspace_outlined,
                    tooltip: 'Delete',
                    size: actionSize,
                    onPressed: onBackspace,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({
    required this.label,
    required this.onPressed,
    required this.size,
  });

  final String label;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PinSmallActionButton extends StatelessWidget {
  const _PinSmallActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
      ),
    );
  }
}
