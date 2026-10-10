import 'package:auto_em_dia/core/services/care_projection_service.dart';
import 'package:auto_em_dia/features/vehicle/domain/mileage_log_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareProjectionService — Projeção Inteligente de Quilometragem', () {
    final now = DateTime(2026, 10, 8);

    test('sem dados suficientes com menos de 2 logs', () {
      final logs = [
        MileageLogEntity(
          id: '1',
          vehicleId: 'veh-1',
          mileage: 50000,
          date: now.subtract(const Duration(days: 10)),
        ),
      ];

      final rate = CareProjectionService.calculateKmPerDay(logs: logs, now: now);
      expect(rate.hasEnoughData, isFalse);
      expect(rate.kmPerDay, isNull);
    });

    test('calcula taxa média diária com logs recentes válidos', () {
      final logs = [
        MileageLogEntity(
          id: '1',
          vehicleId: 'veh-1',
          mileage: 50000,
          date: now.subtract(const Duration(days: 20)),
        ),
        MileageLogEntity(
          id: '2',
          vehicleId: 'veh-1',
          mileage: 51000, // rodou 1.000 km em 20 dias = 50 km/dia
          date: now,
        ),
      ];

      final rate = CareProjectionService.calculateKmPerDay(logs: logs, now: now);
      expect(rate.hasEnoughData, isTrue);
      expect(rate.kmPerDay, 50.0);
      expect(rate.totalDaysAnalyzed, 20);
      expect(rate.totalKmLogged, 1000);
    });

    test('estima data de vencimento com base na taxa km/dia', () {
      final projection = CareProjectionService.estimateDate(
        targetMileage: 52000,
        currentMileage: 51000, // faltam 1.000 km
        kmPerDay: 50.0, // a 50 km/dia => 20 dias
        fromDate: now,
      );

      expect(projection, isNotNull);
      expect(projection!.kmRemaining, 1000);
      expect(projection.daysRemaining, 20);
      expect(projection.estimatedDate, now.add(const Duration(days: 20)));
    });
  });
}
