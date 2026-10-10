import 'package:auto_em_dia/core/services/financial_calculation_service.dart';
import 'package:auto_em_dia/features/expenses/domain/expense_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 5 — Experiência, Gastos e Quick Actions', () {
    test('calculateCategoryBreakdown categoriza com precisão e sem inventar dados', () {
      final expenses = [
        ExpenseEntity(
          id: 'exp-1',
          vehicleId: 'veh-1',
          category: 'Combustível',
          description: 'Gasolina comum',
          amount: 250.0,
          expenseDate: DateTime(2026, 10, 1),
        ),
        ExpenseEntity(
          id: 'exp-2',
          vehicleId: 'veh-1',
          category: 'Combustível',
          description: 'Etanol',
          amount: 150.0,
          expenseDate: DateTime(2026, 10, 5),
        ),
        ExpenseEntity(
          id: 'maint_123',
          vehicleId: 'veh-1',
          category: 'Manutenção',
          description: 'Revisão e óleo',
          amount: 600.0,
          expenseDate: DateTime(2026, 10, 2),
        ),
      ];

      final byCat = expenses.map((e) => (category: e.category, amount: e.amount));
      final breakdown = FinancialCalculationService.calculateCategoryBreakdown(byCat);

      // Total = 1000
      expect(breakdown['Combustível']?.totalAmount, 400.0);
      expect(breakdown['Combustível']?.percentage, 40.0);
      expect(breakdown['Combustível']?.hasData, isTrue);

      expect(breakdown['Manutenção']?.totalAmount, 600.0);
      expect(breakdown['Manutenção']?.percentage, 60.0);
      expect(breakdown['Manutenção']?.hasData, isTrue);

      expect(breakdown['Seguro']?.totalAmount, 0.0);
      expect(breakdown['Seguro']?.percentage, 0.0);
      expect(breakdown['Seguro']?.hasData, isFalse);

      expect(breakdown['Impostos']?.totalAmount, 0.0);
      expect(breakdown['Impostos']?.hasData, isFalse);
    });

    test('Identificação de despesa originada de manutenção (maint_ prefix)', () {
      final maintenanceExpense = ExpenseEntity(
        id: 'maint_abc987',
        vehicleId: 'veh-1',
        category: 'Manutenção',
        description: 'Pastilhas de freio',
        amount: 280.0,
        expenseDate: DateTime(2026, 9, 20),
      );

      expect(maintenanceExpense.id.startsWith('maint_'), isTrue);
      final originalMaintId = maintenanceExpense.id.replaceFirst('maint_', '');
      expect(originalMaintId, 'abc987');
    });
  });
}
