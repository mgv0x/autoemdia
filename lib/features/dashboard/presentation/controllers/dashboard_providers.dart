import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/calculation_service.dart';
import '../../../../core/services/care_projection_service.dart';
import '../../../../core/services/financial_calculation_service.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../core/services/vehicle_health_service.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../maintenance/domain/maintenance_entity.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
import '../../../reminders/domain/reminder_entity.dart';
import '../../../reminders/presentation/controllers/reminder_controller.dart';
import '../../../vehicle/domain/vehicle_entity.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';

/// View-model agregado do dashboard inteligente.
class DashboardData {
  const DashboardData({
    required this.vehicle,
    required this.nextMaintenance,
    required this.upcomingRemindersCount,
    required this.overdueCount,
    required this.monthTotal,
    required this.yearTotal,
    required this.recentMaintenances,
    required this.upcomingReminders,
    required this.healthResult,
    required this.costPerKmResult,
    required this.monthlyAverageResult,
    required this.financialBreakdown,
    this.projectedCareDate,
    this.singleInsight,
  });

  final VehicleEntity? vehicle;
  final ReminderEntity? nextMaintenance; // mais próxima por km ou data
  final int upcomingRemindersCount;
  final int overdueCount;
  final double monthTotal;
  final double yearTotal;
  final List<MaintenanceEntity> recentMaintenances;
  final List<ReminderEntity> upcomingReminders;

  // Inteligência & Regras de Cálculo da Fase 4
  final VehicleHealthResult? healthResult;
  final CostPerKmResult? costPerKmResult;
  final MonthlyAverageResult monthlyAverageResult;
  final Map<String, CategoryFinancialSummary> financialBreakdown;
  final ProjectedCareDate? projectedCareDate;
  final VehicleInsight? singleInsight;
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  final maintenances = await ref.watch(maintenanceListProvider.future);
  final reminders = await ref.watch(remindersProvider.future);
  final expenses = await ref.watch(expensesProvider.future);
  final mileageLogs = await ref.watch(activeVehicleMileageLogsProvider.future);

  final now = DateTime.now();

  // Gastos
  final monthTotal = CalculationService.totalForMonth(
    expenses.map((e) => (date: e.expenseDate, amount: e.amount)),
    now.year,
    now.month,
  );
  final yearTotal = CalculationService.totalForYear(
    expenses.map((e) => (date: e.expenseDate, amount: e.amount)),
    now.year,
  );

  // Próxima manutenção: lembrete mais próximo (km ou data), ignorando concluídos.
  ReminderEntity? next;
  if (vehicle != null) {
    next = _pickNextMaintenance(reminders, vehicle.currentMileage);
  }

  final overdue = reminders
      .where((r) => !r.completed && _isOverdue(r, vehicle))
      .length;
  final upcoming = reminders
      .where((r) => !r.completed && !_isOverdue(r, vehicle))
      .take(10)
      .toList();

  // 1. Saúde do Veículo (0–100)
  VehicleHealthResult? healthResult;
  if (vehicle != null) {
    DateTime? lastMileageDate;
    if (mileageLogs.isNotEmpty) {
      lastMileageDate = mileageLogs.first.date;
    }
    if (vehicle.updatedAt != null) {
      if (lastMileageDate == null ||
          vehicle.updatedAt!.isAfter(lastMileageDate)) {
        lastMileageDate = vehicle.updatedAt;
      }
    }
    lastMileageDate ??= vehicle.createdAt;

    healthResult = VehicleHealthService.calculate(
      reminders: reminders,
      currentMileage: vehicle.currentMileage,
      lastMileageUpdate: lastMileageDate,
      now: now,
    );
  }

  // 2. Custo por KM
  CostPerKmResult? costPerKmResult;
  if (vehicle != null) {
    final totalHistoricalCost = CalculationService.totalAll(
      expenses.map((e) => (date: e.expenseDate, amount: e.amount)),
    );
    costPerKmResult = FinancialCalculationService.calculateCostPerKm(
      totalCost: totalHistoricalCost,
      startMileage: vehicle.initialMileage,
      currentMileage: vehicle.currentMileage,
    );
  }

  // 3. Média mensal
  final monthlyAverageResult =
      FinancialCalculationService.calculateMonthlyAverage(
        expenses.map((e) => (date: e.expenseDate, amount: e.amount)),
      );

  // 4. Detalhamento por categoria ("Quanto custa ter meu veículo")
  final financialBreakdown =
      FinancialCalculationService.calculateCategoryBreakdown(
        expenses.map((e) => (category: e.category, amount: e.amount)),
      );

  // 5. Projeção de data para a próxima manutenção por km
  ProjectedCareDate? projectedCare;
  if (next != null && next.dueMileage != null && vehicle != null) {
    final rateResult = CareProjectionService.calculateKmPerDay(
      logs: mileageLogs,
      now: now,
    );
    if (rateResult.hasEnoughData && rateResult.kmPerDay != null) {
      projectedCare = CareProjectionService.estimateDate(
        targetMileage: next.dueMileage!,
        currentMileage: vehicle.currentMileage,
        kmPerDay: rateResult.kmPerDay!,
        fromDate: now,
      );
    }
  }

  // 6. Insight único no mês (máximo 1)
  final singleInsight = InsightsService.generateMonthlyComparisonInsight(
    expenses: expenses.map(
      (e) => (date: e.expenseDate, amount: e.amount, category: e.category),
    ),
    referenceDate: now,
  );

  return DashboardData(
    vehicle: vehicle,
    nextMaintenance: next,
    upcomingRemindersCount: upcoming.length,
    overdueCount: overdue,
    monthTotal: monthTotal,
    yearTotal: yearTotal,
    recentMaintenances: maintenances.take(5).toList(),
    upcomingReminders: upcoming,
    healthResult: healthResult,
    costPerKmResult: costPerKmResult,
    monthlyAverageResult: monthlyAverageResult,
    financialBreakdown: financialBreakdown,
    projectedCareDate: projectedCare,
    singleInsight: singleInsight,
  );
});

ReminderEntity? _pickNextMaintenance(
  List<ReminderEntity> reminders,
  int currentMileage,
) {
  final pending = reminders.where((r) => !r.completed);
  ReminderEntity? best;
  var bestScore = 1 << 62;

  for (final r in pending) {
    var score = 1 << 61;
    if (r.dueMileage != null) {
      final remaining = r.dueMileage! - currentMileage;
      score = remaining < 0 ? -1000000 + remaining : remaining;
    }
    if (r.dueDate != null) {
      final days =
          CalculationService.daysRemaining(r.dueDate!) * 1000; // pesa data
      score = score < days ? score : days;
    }
    if (score < bestScore) {
      bestScore = score;
      best = r;
    }
  }
  return best;
}

bool _isOverdue(ReminderEntity r, VehicleEntity? vehicle) {
  if (r.completed) return false;
  if (r.dueDate != null && CalculationService.daysRemaining(r.dueDate!) < 0) {
    return true;
  }
  if (vehicle != null && r.dueMileage != null) {
    return r.dueMileage! <= vehicle.currentMileage;
  }
  return false;
}
