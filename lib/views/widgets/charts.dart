import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyExpenseLineChart extends StatelessWidget {
  const WeeklyExpenseLineChart({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final int length = data.length;
    final int labelStep = length <= 7 ? 1 : (length / 6).ceil();

    final List<FlSpot> points = List<FlSpot>.generate(
      data.length,
      (int i) => FlSpot(i.toDouble(), data[i]),
    );

    return LineChart(
      LineChartData(
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12),
        ),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= length) {
                  return const SizedBox.shrink();
                }
                final bool isEdge = index == 0 || index == length - 1;
                final bool show = isEdge || index % labelStep == 0;
                if (!show) {
                  return const SizedBox.shrink();
                }
                return Text(
                  'D${index + 1}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: const Color(0xFF0F766E),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({
    super.key,
    required this.data,
    required this.currencySymbol,
  });

  final Map<String, double> data;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final List<Color> palette = <Color>[
      const Color(0xFF0F766E),
      const Color(0xFFE76F51),
      const Color(0xFF457B9D),
      const Color(0xFF2A9D8F),
      const Color(0xFFF4A261),
      const Color(0xFF264653),
    ];

    final List<MapEntry<String, double>> values = data.entries.toList();
    final double total = values.fold(
      0,
      (double s, MapEntry<String, double> e) => s + e.value,
    );

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: List<PieChartSectionData>.generate(values.length, (
                int i,
              ) {
                final MapEntry<String, double> e = values[i];
                final double percent = total == 0 ? 0 : (e.value / total) * 100;
                return PieChartSectionData(
                  color: palette[i % palette.length],
                  value: e.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 56,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ListView(
            shrinkWrap: true,
            children: List<Widget>.generate(values.length, (int i) {
              final MapEntry<String, double> e = values[i];
              final Color color = palette[i % palette.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Container(width: 10, height: 10, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${e.key}: $currencySymbol${e.value.toStringAsFixed(0)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
