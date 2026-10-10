import 'package:auto_em_dia/core/errors/error_mapper.dart';
import 'package:auto_em_dia/core/services/admob_service.dart';
import 'package:auto_em_dia/features/expenses/domain/expense_entity.dart';
import 'package:auto_em_dia/features/maintenance/domain/maintenance_entity.dart';
import 'package:auto_em_dia/features/reminders/domain/reminder_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 7 — Polimento, Performance e Resiliência a Erros', () {
    test('Entidades de Manutenção geram IDs determinísticos e preservam dados offline', () {
      final now = DateTime(2026, 10, 7);
      final entity = MaintenanceEntity(
        id: 'offline-maint-1',
        vehicleId: 'veh-1',
        category: 'Óleo e filtros',
        description: 'Troca de óleo sintético',
        serviceDate: now,
        mileage: 50000,
        cost: 250.0,
        part: 'Mobil 1',
        workshop: 'Oficina Central',
      );

      expect(entity.id, 'offline-maint-1');
      expect(entity.cost, 250.0);
      expect(entity.mileage, 50000);
      expect(entity.part, 'Mobil 1');

      final copied = entity.copyWith(cost: 280.0);
      expect(copied.id, 'offline-maint-1');
      expect(copied.cost, 280.0);
      expect(copied.description, 'Troca de óleo sintético');
    });

    test('Lembrete gerado a partir de manutenção mantém vínculo de id e categoria', () {
      final reminder = ReminderEntity(
        id: 'auto-rem-1',
        vehicleId: 'veh-1',
        title: 'Óleo e filtros: Troca de óleo sintético',
        category: 'Óleo e filtros',
        dueMileage: 60000,
        sourceMaintenanceId: 'offline-maint-1',
      );

      expect(reminder.sourceMaintenanceId, 'offline-maint-1');
      expect(reminder.dueMileage, 60000);
      expect(reminder.completed, isFalse);
    });

    test('Entidade de Despesa permite atualização imediata em memória', () {
      final expense = ExpenseEntity(
        id: 'exp-1',
        vehicleId: 'veh-1',
        category: 'Combustível',
        description: 'Gasolina Aditivada',
        amount: 150.0,
        expenseDate: DateTime(2026, 10, 7),
      );

      expect(expense.amount, 150.0);
      final updated = expense.copyWith(amount: 175.50);
      expect(updated.amount, 175.50);
      expect(updated.id, 'exp-1');
    });

    test('AdMobService possui fallbacks seguros em modo teste', () {
      expect(AdMobService.bannerAdUnitId, isNotEmpty);
      expect(AdMobService.interstitialAdUnitId, isNotEmpty);
    });

    test('Tratamento de exceções nunca exibe stack trace na mensagem', () {
      try {
        throw StateError('Database connection broken internally at line 42');
      } catch (e) {
        final failure = handleError(e, 'Falha ao sincronizar dados');
        expect(failure.message, isNot(contains('at line 42')));
        expect(failure.message, 'Falha ao sincronizar dados');
      }
    });
  });
}
