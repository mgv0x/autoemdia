import 'package:auto_em_dia/core/services/vehicle_health_service.dart';
import 'package:auto_em_dia/features/reminders/domain/reminder_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleHealthService — Cálculo de Saúde do Veículo (0–100)', () {
    final now = DateTime(2026, 10, 8);

    test('sem dados suficientes quando há menos de 2 itens cadastrados', () {
      final reminders = [
        ReminderEntity(
          id: '1',
          vehicleId: 'veh-1',
          title: 'Troca de óleo',
          category: 'Óleo e filtros',
          dueMileage: 50000,
        ),
      ];

      final result = VehicleHealthService.calculate(
        reminders: reminders,
        currentMileage: 40000,
        now: now,
      );

      expect(result.hasEnoughData, isFalse);
      expect(result.score, isNull);
      expect(result.statusText, 'Sem dados suficientes');
      expect(result.explanation.summary, contains('Ainda não há dados suficientes'));
    });

    test('100 pontos quando todos os itens monitorados estão em dia', () {
      final reminders = [
        ReminderEntity(
          id: '1',
          vehicleId: 'veh-1',
          title: 'Troca de óleo',
          category: 'Óleo e filtros',
          dueMileage: 55000,
          leadKm: 1000,
        ),
        ReminderEntity(
          id: '2',
          vehicleId: 'veh-1',
          title: 'Pastilha de freio',
          category: 'Freios',
          dueMileage: 60000,
          leadKm: 1000,
        ),
      ];

      final result = VehicleHealthService.calculate(
        reminders: reminders,
        currentMileage: 50000,
        now: now,
      );

      expect(result.hasEnoughData, isTrue);
      expect(result.score, 100);
      expect(result.statusText, 'em boas condições');
      expect(result.explanation.positiveItems.length, 2);
      expect(result.explanation.criticalItems, isEmpty);
    });

    test('penalização por item vencido e identificação crítica na explicação', () {
      final reminders = [
        ReminderEntity(
          id: '1',
          vehicleId: 'veh-1',
          title: 'Troca de óleo',
          category: 'Óleo e filtros',
          dueMileage: 48000, // vencido, pois km atual é 50000
        ),
        ReminderEntity(
          id: '2',
          vehicleId: 'veh-1',
          title: 'Pastilha de freio',
          category: 'Freios',
          dueMileage: 60000, // em dia
        ),
      ];

      final result = VehicleHealthService.calculate(
        reminders: reminders,
        currentMileage: 50000,
        now: now,
      );

      expect(result.hasEnoughData, isTrue);
      // Como óleo tem peso 20 e freios tem peso 20, ambos normalizados a 50% cada.
      // Óleo = 0%, Freios = 100% => Total = 50
      expect(result.score, 50);
      expect(result.statusText, 'precisa de cuidados');
      expect(result.explanation.criticalItems, contains('Troca de óleo vencido'));
    });

    test('redistribuição proporcional de pesos entre categorias presentes', () {
      // Três categorias presentes: Revisão (25), Óleo (20), Freios (20)
      // Total pesos base = 65.
      // Se Revisão está em dia (25), Freios em dia (20), e Óleo está em alerta (75% de 20 = 15):
      // Score = (25 + 20 + 15) / 65 * 100 = 60 / 65 * 100 ≈ 92
      final reminders = [
        ReminderEntity(
          id: '1',
          vehicleId: 'veh-1',
          title: 'Revisão periódica',
          category: 'Revisão',
          dueMileage: 60000,
          leadKm: 1000,
        ),
        ReminderEntity(
          id: '2',
          vehicleId: 'veh-1',
          title: 'Pastilhas',
          category: 'Freios',
          dueMileage: 60000,
          leadKm: 1000,
        ),
        ReminderEntity(
          id: '3',
          vehicleId: 'veh-1',
          title: 'Óleo sintético',
          category: 'Óleo e motor',
          dueMileage: 50500, // dentro da margem de alerta (500 km)
          leadKm: 1000,
        ),
      ];

      final result = VehicleHealthService.calculate(
        reminders: reminders,
        currentMileage: 50000,
        now: now,
      );

      expect(result.hasEnoughData, isTrue);
      expect(result.score, 92);
      expect(result.explanation.warningItems, contains('Óleo sintético vence em breve'));
    });

    test('alerta de quilometragem desatualizada há mais de 30 dias', () {
      final reminders = [
        ReminderEntity(
          id: '1',
          vehicleId: 'veh-1',
          title: 'Item 1',
          category: 'Freios',
          dueMileage: 60000,
        ),
        ReminderEntity(
          id: '2',
          vehicleId: 'veh-1',
          title: 'Item 2',
          category: 'Pneus',
          dueMileage: 70000,
        ),
      ];

      final staleDate = now.subtract(const Duration(days: 40));

      final result = VehicleHealthService.calculate(
        reminders: reminders,
        currentMileage: 50000,
        lastMileageUpdate: staleDate,
        now: now,
      );

      expect(result.hasEnoughData, isTrue);
      expect(result.isMileageStale, isTrue);
      expect(result.staleDays, 40);
    });
  });
}
