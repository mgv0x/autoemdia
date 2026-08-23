import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme.dart';

/// Donut chart estilizado para distribuição de categorias de gastos.
class ExpensesDonutChart extends StatelessWidget {
  const ExpensesDonutChart({super.key, required this.totalsByCategory});

  final Map<String, double> totalsByCategory;

  static const _categoryColors = {
    'Combustível': AppTheme.primaryColor,
    'Manutenção': AppTheme.tertiaryColor,
    'Seguro': AppTheme.successColor,
    'Estacionamento': Color(0xFF0284C7),
    'Lavagem': Color(0xFF059669),
    'Documentação': Color(0xFFD97706),
    'Peças': Color(0xFF7C3AED),
  };

  static const _palette = [
    AppTheme.primaryColor,
    AppTheme.tertiaryColor,
    AppTheme.successColor,
    Color(0xFF0284C7),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    if (totalsByCategory.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Nenhum dado de categoria disponível.',
            style: TextStyle(color: AppTheme.textMutedColor),
          ),
        ),
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        // Donut Chart
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 3,
              sections: [
                for (var i = 0; i < entries.length; i++) ...[
                  PieChartSectionData(
                    value: entries[i].value,
                    showTitle: false,
                    color: _getColor(entries[i].key, i),
                    radius: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Legend List
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < entries.take(4).length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _LegendRow(
                  color: _getColor(entries[i].key, i),
                  label: entries[i].key,
                  percentage: total > 0
                      ? '${(entries[i].value / total * 100).toStringAsFixed(0)}%'
                      : '0%',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getColor(String cat, int index) {
    return _categoryColors[cat] ?? _palette[index % _palette.length];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percentage,
  });

  final Color color;
  final String label;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
