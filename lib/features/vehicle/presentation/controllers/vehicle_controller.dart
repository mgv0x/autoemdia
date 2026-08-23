import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_photo_service.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/firestore_vehicle_repository.dart';
import '../../domain/vehicle_entity.dart';
import '../../domain/vehicle_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return FirestoreVehicleRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// Lista de veículos do usuário.
final vehiclesProvider = FutureProvider<List<VehicleEntity>>((ref) async {
  // Reage a mudanças de auth (login/logout).
  ref.watch(authStreamProvider);
  return ref.watch(vehicleRepositoryProvider).getVehicles();
});

/// ID do veículo ativo selecionado.
class ActiveVehicleIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final activeVehicleIdProvider =
    NotifierProvider<ActiveVehicleIdNotifier, String?>(
      ActiveVehicleIdNotifier.new,
    );

/// Veículo ativo selecionado. Padrão: o primeiro da lista.
final activeVehicleProvider = FutureProvider<VehicleEntity?>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  if (vehicles.isEmpty) return null;
  final selectedId = ref.watch(activeVehicleIdProvider);
  if (selectedId == null) return vehicles.first;
  return vehicles.firstWhere(
    (v) => v.id == selectedId,
    orElse: () => vehicles.first,
  );
});

/// Controller de formulários de veículo.
class VehicleFormController extends Notifier<AsyncValue<VehicleEntity?>> {
  @override
  AsyncValue<VehicleEntity?> build() => const AsyncData(null);

  VehicleRepository get _repo => ref.read(vehicleRepositoryProvider);
  LocalPhotoService get _photos => ref.read(localPhotoServiceProvider);

  Future<VehicleEntity?> create(VehicleEntity vehicle) =>
      _mutate(() => _repo.createVehicle(vehicle));

  Future<VehicleEntity?> update(VehicleEntity vehicle) =>
      _mutate(() => _repo.updateVehicle(vehicle));

  Future<VehicleEntity?> _mutate(
    Future<VehicleEntity> Function() action,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!result.hasError) {
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
    }
    state = result;
    return result.value;
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await _repo.deleteVehicle(id);
      await _photos.deleteVehiclePhoto(id);
      return null;
    });
    if (!result.hasError) {
      ref.read(activeVehicleIdProvider.notifier).set(null);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
    }
    state = result;
    return !result.hasError;
  }

  Future<bool> updateMileage(String vehicleId, int mileage) async {
    final result = await AsyncValue.guard(
      () => _repo.updateMileage(vehicleId, mileage),
    );
    if (!result.hasError) {
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
    }
    return !result.hasError;
  }

  /// Salva a foto no dispositivo e associa o path ao veículo no Firestore.
  Future<bool> saveVehiclePhoto({
    required String vehicleId,
    required String tempFilePath,
    required VehicleEntity currentVehicle,
  }) async {
    final path = await _photos.saveVehiclePhoto(
      vehicleId: vehicleId,
      tempFilePath: tempFilePath,
    );

    final updated = currentVehicle.copyWith(photoPath: path);
    final result = await AsyncValue.guard(() => _repo.updateVehicle(updated));
    if (!result.hasError) {
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
      state = AsyncData(result.value);
    }
    return !result.hasError;
  }
}

final vehicleFormControllerProvider =
    NotifierProvider<VehicleFormController, AsyncValue<VehicleEntity?>>(
      VehicleFormController.new,
    );
