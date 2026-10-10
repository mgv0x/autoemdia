import 'package:auto_em_dia/features/maintenance/data/maintenance_model.dart';
import 'package:auto_em_dia/features/reminders/data/reminder_model.dart';
import 'package:auto_em_dia/features/reminders/domain/reminder_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 3 — Lembretes Recorrentes & Status de Cuidados', () {
    final now = DateTime(2026, 10, 8);

    test('calculateStatus determina overdue, upcoming e upToDate com precisão', () {
      final reminderKm = ReminderEntity(
        id: '1',
        vehicleId: 'veh-1',
        title: 'Troca de óleo',
        dueMileage: 50000,
        leadKm: 1000,
      );

      // 1. Em dia (> 1.000 km de distância)
      expect(reminderKm.calculateStatus(48000, now), CareStatus.upToDate);

      // 2. Próximo (dentro dos 1.000 km de antecedência)
      expect(reminderKm.calculateStatus(49500, now), CareStatus.upcoming);

      // 3. Atrasado (atingiu ou passou a km)
      expect(reminderKm.calculateStatus(50000, now), CareStatus.overdue);
      expect(reminderKm.calculateStatus(50200, now), CareStatus.overdue);
    });

    test('isRecurring identifica corretamente lembretes que se repetem', () {
      final nonRecurring = ReminderEntity(
        id: '1',
        vehicleId: 'veh-1',
        title: 'Lembrete pontual',
      );
      expect(nonRecurring.isRecurring, isFalse);

      final recurringByKm = ReminderEntity(
        id: '2',
        vehicleId: 'veh-1',
        title: 'Troca a cada 10.000 km',
        recurrenceKm: 10000,
      );
      expect(recurringByKm.isRecurring, isTrue);

      final recurringByDays = ReminderEntity(
        id: '3',
        vehicleId: 'veh-1',
        title: 'Troca a cada 180 dias',
        recurrenceDays: 180,
      );
      expect(recurringByDays.isRecurring, isTrue);
    });

    test('ReminderModel serializa e desserializa atributos de recorrência e vínculo', () {
      final model = ReminderModel(
        id: 'rem-1',
        vehicleId: 'veh-1',
        title: 'Revisão periódica',
        type: ReminderType.recurring,
        recurrenceKm: 10000,
        recurrenceDays: 365,
        leadKm: 1000,
        leadDays: 30,
        sourceMaintenanceId: 'maint-123',
      );

      final json = ReminderModel.toJson(model);
      expect(json['type'], 'recurring');
      expect(json['recurrence_km'], 10000);
      expect(json['recurrence_days'], 365);
      expect(json['lead_km'], 1000);
      expect(json['lead_days'], 30);
      expect(json['source_maintenance_id'], 'maint-123');

      final fromJson = ReminderModel.fromJson(json, id: 'rem-1');
      expect(fromJson.isRecurring, isTrue);
      expect(fromJson.recurrenceKm, 10000);
      expect(fromJson.sourceMaintenanceId, 'maint-123');
    });

    test('MaintenanceModel serializa e desserializa campos part e workshop', () {
      final model = MaintenanceModel(
        id: 'm-1',
        vehicleId: 'veh-1',
        category: 'Óleo e filtros',
        description: 'Troca de óleo',
        serviceDate: DateTime(2026, 10, 1),
        cost: 350.0,
        part: 'Óleo Motul 5W30',
        workshop: 'Auto Mecânica Express',
      );

      final json = MaintenanceModel.toJson(model);
      expect(json['part'], 'Óleo Motul 5W30');
      expect(json['workshop'], 'Auto Mecânica Express');

      final fromJson = MaintenanceModel.fromJson(json, id: 'm-1');
      expect(fromJson.part, 'Óleo Motul 5W30');
      expect(fromJson.workshop, 'Auto Mecânica Express');
    });
  });
}
