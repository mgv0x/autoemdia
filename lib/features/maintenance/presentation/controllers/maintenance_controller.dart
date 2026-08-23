import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
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

  Future<MaintenanceEntity?> create(MaintenanceEntity e) =>
      _run(() => _repo.create(e));

  Future<MaintenanceEntity?> update(MaintenanceEntity e) =>
      _run(() => _repo.update(e));

  Future<MaintenanceEntity?> _run(
    Future<MaintenanceEntity> Function() action,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!result.hasError) {
      ref.invalidate(maintenanceListProvider);
    }
    state = result;
    return result.value;
  }

  Future<bool> delete(String id) async {
    final result = await AsyncValue.guard(() async {
      await _repo.delete(id);
      return null;
    });
    if (!result.hasError) ref.invalidate(maintenanceListProvider);
    return !result.hasError;
  }
}

final maintenanceFormControllerProvider =
    NotifierProvider<MaintenanceFormController, AsyncValue<MaintenanceEntity?>>(
      MaintenanceFormController.new,
    );
