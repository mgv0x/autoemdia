import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
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
  return ref.watch(expenseRepositoryProvider).getByVehicle(vehicle.id);
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
    if (!result.hasError) ref.invalidate(expensesProvider);
    state = result;
    return result.value;
  }

  Future<bool> delete(String id) async {
    final result = await AsyncValue.guard(() async {
      await _repo.delete(id);
      return null;
    });
    if (!result.hasError) ref.invalidate(expensesProvider);
    return !result.hasError;
  }
}

final expenseFormControllerProvider =
    NotifierProvider<ExpenseFormController, AsyncValue<ExpenseEntity?>>(
      ExpenseFormController.new,
    );
