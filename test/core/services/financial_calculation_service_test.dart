import 'package:auto_em_dia/core/services/financial_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinancialCalculationService — Regras de Cálculo Financeiro', () {
    test('custo por km exige pelo menos 100 km rodados', () {
      final resultBelowThreshold = FinancialCalculationService.calculateCostPerKm(
        totalCost: 500.0,
        startMileage: 50000,
        currentMileage: 50050, // apenas 50 km
      );

      expect(resultBelowThreshold.hasEnoughData, isFalse);
      expect(resultBelowThreshold.costPerKm, isNull);
      expect(resultBelowThreshold.message, contains('pelo menos 100 km'));

      final resultValid = FinancialCalculationService.calculateCostPerKm(
        totalCost: 500.0,
        startMileage: 50000,
        currentMileage: 51000, // 1.000 km
      );

      expect(resultValid.hasEnoughData, isTrue);
      expect(resultValid.costPerKm, 0.5);
      expect(resultValid.kmDriven, 1000);
    });

    test('média mensal computa apenas meses com registros reais', () {
      final expenses = <({DateTime date, double amount})>[
        (date: DateTime(2026, 1, 10), amount: 300.0),
        (date: DateTime(2026, 1, 20), amount: 200.0), // Jan total = 500
        (date: DateTime(2026, 4, 15), amount: 700.0), // Abr total = 700
      ];

      final result = FinancialCalculationService.calculateMonthlyAverage(expenses);

      expect(result.hasEnoughData, isTrue);
      expect(result.distinctMonthsCount, 2);
      expect(result.averageAmount, 600.0); // (500 + 700) / 2
    });

    test('detalhamento por categoria não inventa valores e expõe hasData corretamente', () {
      final expenses = <({String category, double amount})>[
        (category: 'Combustível', amount: 400.0),
        (category: 'Combustível', amount: 200.0),
        (category: 'Manutenção', amount: 400.0),
      ];

      final breakdown = FinancialCalculationService.calculateCategoryBreakdown(expenses);

      // Total = 1000
      expect(breakdown['Combustível']?.totalAmount, 600.0);
      expect(breakdown['Combustível']?.percentage, 60.0);
      expect(breakdown['Combustível']?.hasData, isTrue);

      expect(breakdown['Manutenção']?.totalAmount, 400.0);
      expect(breakdown['Manutenção']?.percentage, 40.0);
      expect(breakdown['Manutenção']?.hasData, isTrue);

      expect(breakdown['Seguro']?.totalAmount, 0.0);
      expect(breakdown['Seguro']?.percentage, 0.0);
      expect(breakdown['Seguro']?.hasData, isFalse);
    });
  });
}
