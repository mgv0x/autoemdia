import 'package:auto_em_dia/core/services/insights_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InsightsService — Geração de Insights Relevantes', () {
    final refDate = DateTime(2026, 10, 15); // Outubro 2026

    test('retorna null se não houver gastos no mês anterior', () {
      final expenses = <({DateTime date, double amount, String category})>[
        (date: DateTime(2026, 10, 5), amount: 500.0, category: 'Combustível'),
      ];

      final insight = InsightsService.generateMonthlyComparisonInsight(
        expenses: expenses,
        referenceDate: refDate,
      );

      expect(insight, isNull);
    });

    test('retorna null se a variação for menor que 10%', () {
      final expenses = <({DateTime date, double amount, String category})>[
        // Setembro = 1000
        (date: DateTime(2026, 9, 10), amount: 1000.0, category: 'Combustível'),
        // Outubro = 1050 (+5% apenas)
        (date: DateTime(2026, 10, 5), amount: 1050.0, category: 'Combustível'),
      ];

      final insight = InsightsService.generateMonthlyComparisonInsight(
        expenses: expenses,
        referenceDate: refDate,
      );

      expect(insight, isNull);
    });

    test('dispara insight de aumento quando variação >= 10%', () {
      final expenses = <({DateTime date, double amount, String category})>[
        // Setembro = 1000
        (date: DateTime(2026, 9, 10), amount: 1000.0, category: 'Combustível'),
        // Outubro = 1250 (+25%)
        (date: DateTime(2026, 10, 5), amount: 1250.0, category: 'Combustível'),
      ];

      final insight = InsightsService.generateMonthlyComparisonInsight(
        expenses: expenses,
        referenceDate: refDate,
      );

      expect(insight, isNotNull);
      expect(insight!.type, InsightType.increase);
      expect(insight.percentageChange, 25.0);
      expect(insight.title, contains('Gastos em alta'));
    });

    test('dispara insight de economia quando gastos caem >= 10%', () {
      final expenses = <({DateTime date, double amount, String category})>[
        // Setembro = 1000
        (date: DateTime(2026, 9, 10), amount: 1000.0, category: 'Combustível'),
        // Outubro = 800 (-20%)
        (date: DateTime(2026, 10, 5), amount: 800.0, category: 'Combustível'),
      ];

      final insight = InsightsService.generateMonthlyComparisonInsight(
        expenses: expenses,
        referenceDate: refDate,
      );

      expect(insight, isNotNull);
      expect(insight!.type, InsightType.decrease);
      expect(insight.percentageChange, -20.0);
      expect(insight.title, contains('Economia'));
    });
  });
}
