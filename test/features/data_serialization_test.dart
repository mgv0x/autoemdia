import 'package:auto_em_dia/features/expenses/data/expense_model.dart';
import 'package:auto_em_dia/features/maintenance/data/maintenance_model.dart';
import 'package:auto_em_dia/features/reminders/data/reminder_model.dart';
import 'package:auto_em_dia/features/vehicle/data/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleModel (serialização Firestore)', () {
    test('fromJson corretamente', () {
      final json = {
        'user_id': 'user-1',
        'brand': 'Honda',
        'model': 'Civic',
        'year': 2018,
        'fuel': 'Flex',
        'current_mileage': 92450,
      };
      final v = VehicleModel.fromJson(json, id: 'veh-1');
      expect(v.id, 'veh-1');
      expect(v.brand, 'Honda');
      expect(v.currentMileage, 92450);
    });

    test('toJson para salvar novo veículo', () {
      final json = VehicleModel.toJson(
        const VehicleModel(
          id: '',
          userId: '',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          fuel: 'Flex',
          currentMileage: 50000,
        ),
        userId: 'u-1',
      );
      expect(json['user_id'], 'u-1');
      expect(json['brand'], 'Toyota');
      expect(json['current_mileage'], 50000);
    });
  });

  group('MaintenanceModel (serialização Firestore)', () {
    test('fromJson/toJson round-trip', () {
      final json = {
        'vehicle_id': 'veh-1',
        'category': 'Óleo e filtros',
        'description': 'Troca de óleo',
        'service_date': Timestamp.fromDate(DateTime(2026, 8, 1)),
        'mileage': 92450,
        'cost': 320.0,
        'notes': 'Óleo sintético',
        'next_mileage': 97450,
        'next_date': Timestamp.fromDate(DateTime(2027, 2, 1)),
        'created_at': Timestamp.now(),
      };
      final m = MaintenanceModel.fromJson(json, id: 'm-1');
      expect(m.id, 'm-1');
      expect(m.description, 'Troca de óleo');
      expect(m.mileage, 92450);
      expect(m.nextMileage, 97450);
    });
  });

  group('ReminderModel (serialização Firestore)', () {
    test('fromJson', () {
      final json = {
        'vehicle_id': 'veh-1',
        'title': 'Troca de óleo',
        'category': 'Óleo e filtros',
        'due_date': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'due_mileage': 95000,
        'completed': false,
        'notification_enabled': true,
        'created_at': Timestamp.now(),
      };
      final r = ReminderModel.fromJson(json, id: 'r-1');
      expect(r.title, 'Troca de óleo');
      expect(r.dueMileage, 95000);
      expect(r.completed, isFalse);
    });
  });

  group('ExpenseModel (serialização Firestore)', () {
    test('fromJson', () {
      final json = {
        'vehicle_id': 'veh-1',
        'category': 'Combustível',
        'description': 'Etanol completo',
        'amount': 150.0,
        'expense_date': Timestamp.fromDate(DateTime(2026, 8, 10)),
        'created_at': Timestamp.now(),
      };
      final e = ExpenseModel.fromJson(json, id: 'e-1');
      expect(e.amount, 150.0);
      expect(e.category, 'Combustível');
    });
  });
}
