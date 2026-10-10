import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_providers.dart';
import '../../../expenses/domain/expense_entity.dart';
import '../../../expenses/domain/expense_repository.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../data/firestore_maintenance_repository.dart';
import '../../domain/maintenance_entity.dart';
import '../../domain/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return FirestoreMaintenanceRepository(ref.watch(firestoreProvider));
});

/// Manutenções do veículo ativo.
final maintenanceListProvider = FutureProvider<List<MaintenanceEntity>>((
  ref,
) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  if (vehicle == null) return <MaintenanceEntity>[];
  return ref.watch(maintenanceRepositoryProvider).getByVehicle(vehicle.id);
});

/// Filtro de categoria selecionado na lista de manutenções.
class MaintenanceCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final maintenanceCategoryFilterProvider =
    NotifierProvider<MaintenanceCategoryFilterNotifier, String?>(
      MaintenanceCategoryFilterNotifier.new,
    );

class MaintenanceFormController
    extends Notifier<AsyncValue<MaintenanceEntity?>> {
  @override
  AsyncValue<MaintenanceEntity?> build() => const AsyncData(null);

  MaintenanceRepository get _repo => ref.read(maintenanceRepositoryProvider);
  ExpenseRepository get _expenseRepo => ref.read(expenseRepositoryProvider);

  Future<MaintenanceEntity?> create(MaintenanceEntity e) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final saved = await _repo.create(e);
      if (saved.cost != null && saved.cost! > 0) {
        await _syncExpense(saved);
      }
      return saved;
    });
    if (!result.hasError) {
      ref.invalidate(maintenanceListProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardDataProvider);
    }
    state = result;
    return result.value;
  }

  Future<MaintenanceEntity?> update(MaintenanceEntity e) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final updated = await _repo.update(e);
      if (updated.cost != null && updated.cost! > 0) {
        await _syncExpense(updated);
      } else {
        await _removeExpense('maint_${updated.id}');
      }
      return updated;
    });
    if (!result.hasError) {
      ref.invalidate(maintenanceListProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardDataProvider);
    }
    state = result;
    return result.value;
  }

  Future<bool> delete(String id) async {
    final result = await AsyncValue.guard(() async {
      await _repo.delete(id);
      await _removeExpense('maint_$id');
      return null;
    });
    if (!result.hasError) {
      ref.invalidate(maintenanceListProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardDataProvider);
    }
    return !result.hasError;
  }

  Future<void> _syncExpense(MaintenanceEntity m) async {
    try {
      final expense = ExpenseEntity(
        id: 'maint_${m.id}',
        vehicleId: m.vehicleId,
        category: 'Manutenção',
        description: '${m.category}: ${m.description}',
        amount: m.cost!,
        expenseDate: m.serviceDate,
      );
      // update usa SetOptions(merge: true), criando se não existir ou atualizando se existir
      await _expenseRepo.update(expense);
    } catch (_) {}
  }

  Future<void> _removeExpense(String expenseId) async {
    try {
      await _expenseRepo.delete(expenseId);
    } catch (_) {}
  }
}

final maintenanceFormControllerProvider =
    NotifierProvider<MaintenanceFormController, AsyncValue<MaintenanceEntity?>>(
      MaintenanceFormController.new,
    );
