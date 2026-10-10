import 'calculation_service.dart';

/// Tipo de insight financeiro.
enum InsightType {
  increase, // Gastos subiram
  decrease, // Gastos caíram / economia
  neutral,  // Estável
}

/// Item de insight automotivo com base em dados reais.
class VehicleInsight {
  const VehicleInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.percentageChange,
    this.category,
  });

  final InsightType type;
  final String title;
  final String message;
  final double percentageChange;
  final String? category;
}

/// Serviço de geração de insights automotivos inteligentes (máximo 1 insight na Home).
abstract final class InsightsService {
  /// Limiar percentual mínimo (10%) para considerar uma variação relevante.
  static const minimumRelevanceThresholdPercent = 10.0;

  /// Gera no máximo 1 insight prioritário comparando o mês atual com o mês anterior.
  /// Retorna null se não houver dados suficientes no mês anterior ou se a variação for menor que 10%.
  static VehicleInsight? generateMonthlyComparisonInsight({
    required Iterable<({DateTime date, double amount, String category})> expenses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Determina mês anterior
    final previousMonthDate = DateTime(currentYear, currentMonth - 1, 1);
    final prevYear = previousMonthDate.year;
    final prevMonth = previousMonthDate.month;

    final currentMonthExpenses = expenses
        .where((e) => e.date.year == currentYear && e.date.month == currentMonth)
        .toList();
    final prevMonthExpenses = expenses
        .where((e) => e.date.year == prevYear && e.date.month == prevMonth)
        .toList();

    // Regra: exige dados no mês anterior para haver termo de comparação
    if (prevMonthExpenses.isEmpty) return null;

    final currentTotal = CalculationService.sum(currentMonthExpenses.map((e) => e.amount));
    final prevTotal = CalculationService.sum(prevMonthExpenses.map((e) => e.amount));

    if (prevTotal <= 0) return null;

    final percentChange = ((currentTotal - prevTotal) / prevTotal) * 100.0;

    // Variações menores que o limiar (10%) não disparam insight
    if (percentChange.abs() < minimumRelevanceThresholdPercent) {
      return null;
    }

    if (percentChange > 0) {
      final formattedPercent = percentChange.round();
      return VehicleInsight(
        type: InsightType.increase,
        title: 'Gastos em alta neste mês',
        message: 'Seus gastos no mês atual estão $formattedPercent% acima do fechamento do mês anterior.',
        percentageChange: percentChange,
      );
    } else {
      final formattedSavings = percentChange.abs().round();
      return VehicleInsight(
        type: InsightType.decrease,
        title: 'Economia identificada',
        message: 'Seus gastos totais estão $formattedSavings% menores em comparação ao mês passado.',
        percentageChange: percentChange,
      );
    }
  }
}
