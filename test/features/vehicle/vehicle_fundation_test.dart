import 'package:auto_em_dia/core/utils/validators.dart';
import 'package:auto_em_dia/features/vehicle/data/mileage_log_model.dart';
import 'package:auto_em_dia/features/vehicle/data/vehicle_model.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_type.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_type_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 2 — Fundação e Migração de Veículos', () {
    test('Migração legada: registro antigo sem type vira Carro por padrão', () {
      final legacyJson = {
        'user_id': 'user-legacy-123',
        'brand': 'Honda',
        'model': 'Civic',
        'year': 2018,
        'fuel': 'Flex',
        'current_mileage': 92450,
        // Atenção: type, initial_mileage, version NÃO existem no banco legado
      };

      final vehicle = VehicleModel.fromJson(legacyJson, id: 'veh-legacy-1');

      expect(vehicle.id, 'veh-legacy-1');
      expect(vehicle.type, VehicleType.car);
      expect(vehicle.isCar, isTrue);
      expect(vehicle.isMotorcycle, isFalse);
      expect(vehicle.brand, 'Honda');
      expect(vehicle.model, 'Civic');
      expect(vehicle.currentMileage, 92450);
      expect(vehicle.initialMileage, 92450, reason: 'Herda current_mileage se initial_mileage for ausente');
      expect(vehicle.version, isNull);
      expect(vehicle.displacement, isNull);
      expect(vehicle.displayName, 'Honda Civic 2018');
    });

    test('Cadastro e serialização de Moto com cilindrada e versão', () {
      final moto = VehicleModel(
        id: 'moto-1',
        userId: 'user-1',
        type: VehicleType.motorcycle,
        brand: 'Yamaha',
        model: 'MT-07',
        version: 'ABS',
        year: 2023,
        fuel: 'Gasolina',
        plate: 'BRA2E19',
        currentMileage: 8500,
        initialMileage: 0,
        displacement: 689,
      );

      expect(moto.isMotorcycle, isTrue);
      expect(moto.displayName, 'Yamaha MT-07 ABS 2023');

      final json = VehicleModel.toJson(moto, userId: 'user-1');
      expect(json['type'], 'motorcycle');
      expect(json['brand'], 'Yamaha');
      expect(json['displacement'], 689);
      expect(json['version'], 'ABS');

      // Round-trip fromJson
      final restored = VehicleModel.fromJson(json, id: 'moto-1');
      expect(restored.type, VehicleType.motorcycle);
      expect(restored.displacement, 689);
      expect(restored.version, 'ABS');
    });

    test('VehicleTypeConfig fornece categorias e termos corretos por tipo', () {
      final carConfig = VehicleTypeConfig.of(VehicleType.car);
      expect(carConfig.label, 'Carro');
      expect(carConfig.showDisplacement, isFalse);
      expect(carConfig.maintenanceCategories, contains('Ar-condicionado'));
      expect(carConfig.maintenanceCategories, contains('Direção'));

      final motoConfig = VehicleTypeConfig.of(VehicleType.motorcycle);
      expect(motoConfig.label, 'Moto');
      expect(motoConfig.showDisplacement, isTrue);
      expect(motoConfig.maintenanceCategories, contains('Relação (corrente, pinhão e coroa)'));
      expect(motoConfig.maintenanceCategories, isNot(contains('Ar-condicionado')));
      expect(motoConfig.intervalSuggestions.any((s) => s.title.contains('Lubrificação da corrente')), isTrue);
    });

    test('MileageLogModel serializa e desserializa corretamente', () {
      final now = DateTime(2026, 10, 7);
      final logJson = {
        'vehicle_id': 'veh-1',
        'mileage': 95000,
        'date': '2026-10-07',
        'source': 'maintenance',
        'created_at': Timestamp.fromDate(now),
      };

      final log = MileageLogModel.fromJson(logJson, id: 'log-1');
      expect(log.id, 'log-1');
      expect(log.vehicleId, 'veh-1');
      expect(log.mileage, 95000);
      expect(log.source, 'maintenance');

      final exported = MileageLogModel.toJson(log);
      expect(exported['vehicle_id'], 'veh-1');
      expect(exported['mileage'], 95000);
      expect(exported['date'], '2026-10-07');
    });

    test('Validador de placa identifica formatos Mercosul e antigo', () {
      expect(Validators.isBrazilianPlate('ABC1D23'), isTrue); // Mercosul
      expect(Validators.isBrazilianPlate('ABC-1234'), isTrue); // Antiga com hífen
      expect(Validators.isBrazilianPlate('ABC1234'), isTrue); // Antiga sem hífen
      expect(Validators.isBrazilianPlate('abc1d23'), isTrue); // Minúscula
      expect(Validators.isBrazilianPlate('12345'), isFalse);
      expect(Validators.isBrazilianPlate('INVALIDO'), isFalse);
    });
  });
}
