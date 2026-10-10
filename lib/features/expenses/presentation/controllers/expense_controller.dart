import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../data/firestore_expense_repository.dart';
import '../../domain/expense_entity.dart';
import '../../domain/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirestoreExpenseRepository(ref.watch(firestoreProvider));
});

final expensesProvider = FutureProvider<List<ExpenseEntity>>((ref) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  if (vehicle == null) return <ExpenseEntity>[];

  final expenses = await ref
      .watch(expenseRepositoryProvider)
      .getByVehicle(vehicle.id);
  final maintenances = await ref.watch(maintenanceListProvider.future);

  final list = List<ExpenseEntity>.from(expenses);

  // Garante que qualquer manutenção com custo que ainda não esteja em expenses seja incluída
  for (final m in maintenances) {
    if (m.cost != null && m.cost! > 0) {
      final exists = list.any(
        (e) =>
            e.id == 'maint_${m.id}' ||
            (e.description == '${m.category}: ${m.description}' &&
                (e.amount - m.cost!).abs() < 0.01 &&
                e.expenseDate.year == m.serviceDate.year &&
                e.expenseDate.month == m.serviceDate.month &&
                e.expenseDate.day == m.serviceDate.day),
      );
      if (!exists) {
        list.add(
          ExpenseEntity(
            id: 'maint_${m.id}',
            vehicleId: m.vehicleId,
            category: 'Manutenção',
            description: '${m.category}: ${m.description}',
            amount: m.cost!,
            expenseDate: m.serviceDate,
          ),
        );
      }
    }
  }

  list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  return list;
});

class ExpenseFormController extends Notifier<AsyncValue<ExpenseEntity?>> {
  @override
  AsyncValue<ExpenseEntity?> build() => const AsyncData(null);

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  Future<ExpenseEntity?> create(ExpenseEntity e) => _run(() => _repo.create(e));

  Future<ExpenseEntity?> update(ExpenseEntity e) => _run(() => _repo.update(e));

  Future<ExpenseEntity?> _run(Future<ExpenseEntity> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!result.hasError) {
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardDataProvider);
    }
    state = result;
    return result.value;
  }

  Future<bool> delete(String id) async {
    final result = await AsyncValue.guard(() async {
      await _repo.delete(id);
      return null;
    });
    if (!result.hasError) {
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardDataProvider);
    }
    return !result.hasError;
  }
}

final expenseFormControllerProvider =
    NotifierProvider<ExpenseFormController, AsyncValue<ExpenseEntity?>>(
      ExpenseFormController.new,
    );
