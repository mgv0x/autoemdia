import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/calculation_service.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../maintenance/domain/maintenance_entity.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
import '../../../reminders/domain/reminder_entity.dart';
import '../../../reminders/presentation/controllers/reminder_controller.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../../vehicle/domain/vehicle_entity.dart';

/// View-model agregado do dashboard.
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
  });

  final VehicleEntity? vehicle;
  final ReminderEntity? nextMaintenance; // mais próxima por km ou data
  final int upcomingRemindersCount;
  final int overdueCount;
  final double monthTotal;
  final double yearTotal;
  final List<MaintenanceEntity> recentMaintenances;
  final List<ReminderEntity> upcomingReminders;
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  final maintenances = await ref.watch(maintenanceListProvider.future);
  final reminders = await ref.watch(remindersProvider.future);
  final expenses = await ref.watch(expensesProvider.future);

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

  return DashboardData(
    vehicle: vehicle,
    nextMaintenance: next,
    upcomingRemindersCount: upcoming.length,
    overdueCount: overdue,
    monthTotal: monthTotal,
    yearTotal: yearTotal,
    recentMaintenances: maintenances.take(5).toList(),
    upcomingReminders: upcoming,
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
