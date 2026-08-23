/// Serviços de cálculo financeiro e de manutenção (regras fora da UI).
abstract final class CalculationService {
  /// Soma de valores de uma lista.
  static double sum(Iterable<double> values) =>
      values.fold(0.0, (a, b) => a + b);

  /// Total de despesas em um mês/ano específicos.
  static double totalForMonth(
    Iterable<({DateTime date, double amount})> expenses,
    int year,
    int month,
  ) {
    return sum(
      expenses
          .where((e) => e.date.year == year && e.date.month == month)
          .map((e) => e.amount),
    );
  }

  /// Total de despesas em um ano específico.
  static double totalForYear(
    Iterable<({DateTime date, double amount})> expenses,
    int year,
  ) {
    return sum(expenses.where((e) => e.date.year == year).map((e) => e.amount));
  }

  /// Total histórico.
  static double totalAll(Iterable<({DateTime date, double amount})> expenses) =>
      sum(expenses.map((e) => e.amount));

  /// Custo por quilômetro: total de custos / km percorridos.
  /// Retorna 0 quando não há km percorridos válidos.
  static double costPerKm({
    required double totalCost,
    required int startMileage,
    required int currentMileage,
  }) {
    final kmDriven = currentMileage - startMileage;
    if (kmDriven <= 0) return 0;
    return totalCost / kmDriven;
  }

  /// Agrupa totais por categoria.
  static Map<String, double> totalsByCategory(
    Iterable<({String category, double amount})> expenses,
  ) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// km restantes até uma meta. Pode ser negativo (atrasado).
  static int kmRemaining({
    required int currentMileage,
    required int targetMileage,
  }) => targetMileage - currentMileage;

  /// Dias restantes até uma data (negativo = atrasado).
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }
}
