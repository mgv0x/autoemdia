import 'package:auto_em_dia/core/services/calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculationService', () {
    final expenses = <({DateTime date, double amount})>[
      (date: DateTime(2026, 1, 10), amount: 150.0), // jan
      (date: DateTime(2026, 1, 20), amount: 350.5), // jan
      (date: DateTime(2026, 8, 5), amount: 800.0), // ago
      (date: DateTime(2025, 12, 31), amount: 99.9), // ano anterior
    ];

    test('total do mês', () {
      expect(
        CalculationService.totalForMonth(expenses, 2026, 1),
        closeTo(500.5, 0.001),
      );
      expect(CalculationService.totalForMonth(expenses, 2026, 2), 0);
    });

    test('total do ano', () {
      expect(
        CalculationService.totalForYear(expenses, 2026),
        closeTo(1300.5, 0.001),
      );
      expect(
        CalculationService.totalForYear(expenses, 2025),
        closeTo(99.9, 0.001),
      );
    });

    test('total histórico', () {
      expect(CalculationService.totalAll(expenses), closeTo(1400.4, 0.001));
    });

    test('custo por km', () {
      expect(
        CalculationService.costPerKm(
          totalCost: 1000,
          startMileage: 90000,
          currentMileage: 92000,
        ),
        closeTo(0.5, 0.001),
      );
    });

    test('custo por km zero quando sem km percorridos', () {
      expect(
        CalculationService.costPerKm(
          totalCost: 1000,
          startMileage: 90000,
          currentMileage: 90000,
        ),
        0,
      );
      expect(
        CalculationService.costPerKm(
          totalCost: 1000,
          startMileage: 92000,
          currentMileage: 90000,
        ),
        0,
      );
    });

    test('totalsByCategory', () {
      final data = <({String category, double amount})>[
        (category: 'Combustível', amount: 200),
        (category: 'Manutenção', amount: 500),
        (category: 'Combustível', amount: 100),
      ];
      final map = CalculationService.totalsByCategory(data);
      expect(map['Combustível'], 300);
      expect(map['Manutenção'], 500);
      expect(map['Seguro'], isNull);
    });

    test('daysRemaining', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(CalculationService.daysRemaining(tomorrow), 1);
    });
  });
}
