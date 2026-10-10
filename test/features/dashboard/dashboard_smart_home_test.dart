import 'package:auto_em_dia/core/services/care_projection_service.dart';
import 'package:auto_em_dia/core/services/financial_calculation_service.dart';
import 'package:auto_em_dia/core/services/insights_service.dart';
import 'package:auto_em_dia/core/services/vehicle_health_service.dart';
import 'package:auto_em_dia/features/dashboard/presentation/controllers/dashboard_providers.dart';
import 'package:auto_em_dia/features/reminders/domain/reminder_entity.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_entity.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 4 — Home Inteligente (DashboardData & Regras de Exibição)', () {
    final vehicle = VehicleEntity(
      id: 'veh-1',
      userId: 'user-1',
      brand: 'Honda',
      model: 'Civic',
      year: 2020,
      fuel: 'Flex',
      plate: 'ABC1D23',
      currentMileage: 50000,
      initialMileage: 40000,
      type: VehicleType.car,
    );

    test('DashboardData instancia corretamente com saúde, custo/km e projeção', () {
      final healthResult = VehicleHealthResult(
        hasEnoughData: true,
        score: 88,
        statusText: 'em boas condições',
        isMileageStale: false,
        explanation: const HealthExplanation(
          positiveItems: ['Óleo em dia', 'Freios em dia'],
          warningItems: [],
          criticalItems: [],
          summary: 'Tudo sob controle',
        ),
        categoryHealth: const {},
      );

      final costPerKm = CostPerKmResult(
        hasEnoughData: true,
        costPerKm: 0.65,
        kmDriven: 10000,
      );

      final projectedCare = ProjectedCareDate(
        targetMileage: 55000,
        kmRemaining: 5000,
        estimatedDate: DateTime(2026, 12, 1),
        daysRemaining: 54,
      );

      final insight = VehicleInsight(
        type: InsightType.increase,
        title: 'Gastos em alta neste mês',
        message: 'Seus gastos no mês atual estão 15% acima do anterior.',
        percentageChange: 15.0,
      );

      final data = DashboardData(
        vehicle: vehicle,
        nextMaintenance: ReminderEntity(
          id: 'rem-1',
          vehicleId: vehicle.id,
          title: 'Troca de óleo',
          dueMileage: 55000,
        ),
        upcomingRemindersCount: 1,
        overdueCount: 0,
        monthTotal: 450.0,
        yearTotal: 2500.0,
        recentMaintenances: [],
        upcomingReminders: [],
        healthResult: healthResult,
        costPerKmResult: costPerKm,
        monthlyAverageResult: const MonthlyAverageResult(
          hasEnoughData: true,
          averageAmount: 350.0,
          distinctMonthsCount: 5,
        ),
        financialBreakdown: const {},
        projectedCareDate: projectedCare,
        singleInsight: insight,
      );

      expect(data.healthResult?.score, 88);
      expect(data.costPerKmResult?.costPerKm, 0.65);
      expect(data.projectedCareDate?.kmRemaining, 5000);
      expect(data.singleInsight?.type, InsightType.increase);
      expect(data.healthResult?.isMileageStale, isFalse);
    });

    test('DashboardData reflete km desatualizada (>30 dias)', () {
      final healthStale = VehicleHealthResult(
        hasEnoughData: true,
        score: 75,
        statusText: 'atenção em alguns itens',
        isMileageStale: true,
        staleDays: 45,
        explanation: const HealthExplanation(
          positiveItems: [],
          warningItems: [],
          criticalItems: [],
          summary: 'Quilometragem precisa de atualização.',
        ),
        categoryHealth: const {},
      );

      final data = DashboardData(
        vehicle: vehicle,
        nextMaintenance: null,
        upcomingRemindersCount: 0,
        overdueCount: 0,
        monthTotal: 0,
        yearTotal: 0,
        recentMaintenances: [],
        upcomingReminders: [],
        healthResult: healthStale,
        costPerKmResult: null,
        monthlyAverageResult: const MonthlyAverageResult(
          hasEnoughData: false,
          distinctMonthsCount: 0,
        ),
        financialBreakdown: const {},
      );

      expect(data.healthResult?.isMileageStale, isTrue);
      expect(data.healthResult?.staleDays, 45);
      expect(data.singleInsight, isNull);
    });
  });
}
