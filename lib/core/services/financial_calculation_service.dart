import 'calculation_service.dart';

/// Resultado detalhado do Custo por KM com validação de dados mínimos.
class CostPerKmResult {
  const CostPerKmResult({
    required this.hasEnoughData,
    this.costPerKm,
    required this.kmDriven,
    this.message,
  });

  final bool hasEnoughData;
  final double? costPerKm;
  final int kmDriven;
  final String? message;
}

/// Resumo de gastos por categoria ("Quanto custa ter meu veículo").
class CategoryFinancialSummary {
  const CategoryFinancialSummary({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.count,
    required this.hasData,
  });

  final String category;
  final double totalAmount;
  final double percentage;
  final int count;
  final bool hasData;
}

/// Média mensal de despesas.
class MonthlyAverageResult {
  const MonthlyAverageResult({
    required this.hasEnoughData,
    this.averageAmount,
    required this.distinctMonthsCount,
    this.message,
  });

  final bool hasEnoughData;
  final double? averageAmount;
  final int distinctMonthsCount;
  final String? message;
}

/// Serviço avançado de cálculos financeiros automotivos.
abstract final class FinancialCalculationService {
  /// Quilometragem mínima necessária para calcular custo por km confiável.
  static const minimumKmForCostPerKm = 100;

  /// Categorias principais para o relatório "Quanto custa ter meu veículo".
  static const standardCategories = [
    'Combustível',
    'Manutenção',
    'Seguro',
    'Impostos',
    'Outros',
  ];

  /// Calcula o custo por quilômetro com regra de dados suficientes (mínimo 100 km rodados).
  static CostPerKmResult calculateCostPerKm({
    required double totalCost,
    required int startMileage,
    required int currentMileage,
  }) {
    final kmDriven = currentMileage - startMileage;

    if (kmDriven < minimumKmForCostPerKm) {
      return CostPerKmResult(
        hasEnoughData: false,
        costPerKm: null,
        kmDriven: kmDriven < 0 ? 0 : kmDriven,
        message: 'Necessário rodar pelo menos $minimumKmForCostPerKm km para calcular o custo por quilômetro.',
      );
    }

    if (totalCost <= 0) {
      return CostPerKmResult(
        hasEnoughData: false,
        costPerKm: null,
        kmDriven: kmDriven,
        message: 'Nenhum gasto registrado para o cálculo.',
      );
    }

    final cost = totalCost / kmDriven;
    return CostPerKmResult(
      hasEnoughData: true,
      costPerKm: cost,
      kmDriven: kmDriven,
    );
  }

  /// Média mensal baseada exclusivamente nos meses que possuem registros.
  static MonthlyAverageResult calculateMonthlyAverage(
    Iterable<({DateTime date, double amount})> expenses,
  ) {
    if (expenses.isEmpty) {
      return const MonthlyAverageResult(
        hasEnoughData: false,
        averageAmount: null,
        distinctMonthsCount: 0,
        message: 'Sem dados suficientes para calcular a média mensal.',
      );
    }

    final total = CalculationService.sum(expenses.map((e) => e.amount));
    final distinctMonths = expenses.map((e) => '${e.date.year}-${e.date.month}').toSet();

    if (distinctMonths.isEmpty || total <= 0) {
      return const MonthlyAverageResult(
        hasEnoughData: false,
        averageAmount: null,
        distinctMonthsCount: 0,
        message: 'Sem gastos válidos no período.',
      );
    }

    final average = total / distinctMonths.length;
    return MonthlyAverageResult(
      hasEnoughData: true,
      averageAmount: average,
      distinctMonthsCount: distinctMonths.length,
    );
  }

  /// Distribuição e detalhamento por categoria ("Quanto custa ter meu veículo").
  static Map<String, CategoryFinancialSummary> calculateCategoryBreakdown(
    Iterable<({String category, double amount})> expenses, {
    List<String> expectedCategories = standardCategories,
  }) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    double grandTotal = 0.0;

    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0.0) + e.amount;
      counts[e.category] = (counts[e.category] ?? 0) + 1;
      grandTotal += e.amount;
    }

    final result = <String, CategoryFinancialSummary>{};

    // Preenche categorias padrão
    for (final cat in expectedCategories) {
      final total = totals[cat] ?? 0.0;
      final count = counts[cat] ?? 0;
      final percentage = grandTotal > 0 ? (total / grandTotal) * 100.0 : 0.0;

      result[cat] = CategoryFinancialSummary(
        category: cat,
        totalAmount: total,
        percentage: percentage,
        count: count,
        hasData: count > 0 && total > 0,
      );
    }

    // Adiciona quaisquer categorias adicionais não previstas
    for (final entry in totals.entries) {
      if (!result.containsKey(entry.key)) {
        final total = entry.value;
        final count = counts[entry.key] ?? 0;
        final percentage = grandTotal > 0 ? (total / grandTotal) * 100.0 : 0.0;

        result[entry.key] = CategoryFinancialSummary(
          category: entry.key,
          totalAmount: total,
          percentage: percentage,
          count: count,
          hasData: count > 0 && total > 0,
        );
      }
    }

    return result;
  }
}
