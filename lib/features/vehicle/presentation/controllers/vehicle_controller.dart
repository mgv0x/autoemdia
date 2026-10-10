import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_photo_service.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/providers/shared_preferences_provider.dart';
import '../../data/firestore_vehicle_repository.dart';
import '../../domain/mileage_log_entity.dart';
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

const _activeVehicleKeyPrefix = 'active_vehicle_id_';

/// ID do veículo ativo selecionado, persistido no SharedPreferences por usuário.
class ActiveVehicleIdNotifier extends Notifier<String?> {
  String _key(String? uid) => '$_activeVehicleKeyPrefix${uid ?? 'anonymous'}';

  @override
  String? build() {
    final auth = ref.watch(authStreamProvider).value;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getString(_key(auth?.id));
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String? id) async {
    final auth = ref.read(authStreamProvider).value;
    state = id;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (id == null) {
        await prefs.remove(_key(auth?.id));
      } else {
        await prefs.setString(_key(auth?.id), id);
      }
    } catch (_) {}
  }
}

final activeVehicleIdProvider =
    NotifierProvider<ActiveVehicleIdNotifier, String?>(
      ActiveVehicleIdNotifier.new,
    );

/// Veículo ativo selecionado.
/// Persistente entre sessões e resiliente a remoções.
final activeVehicleProvider = FutureProvider<VehicleEntity?>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  if (vehicles.isEmpty) return null;
  final selectedId = ref.watch(activeVehicleIdProvider);
  if (selectedId != null) {
    for (final v in vehicles) {
      if (v.id == selectedId) return v;
    }
  }
  return vehicles.first;
});

/// Logs históricos de quilometragem do veículo ativo.
final activeVehicleMileageLogsProvider =
    FutureProvider<List<MileageLogEntity>>((ref) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  if (vehicle == null) return [];
  return ref.watch(vehicleRepositoryProvider).getMileageLogs(vehicle.id);
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
    if (!result.hasError && result.value != null) {
      // Define o veículo recém-criado/atualizado como ativo
      await ref.read(activeVehicleIdProvider.notifier).set(result.value!.id);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
      ref.invalidate(activeVehicleMileageLogsProvider);
    }
    state = result;
    return result.value;
  }

  /// Exclui o veículo e remove em cascata todos os dados associados.
  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await _repo.deleteVehicle(id);
      await _photos.deleteVehiclePhoto(id);
      return null;
    });
    if (!result.hasError) {
      final currentSelected = ref.read(activeVehicleIdProvider);
      if (currentSelected == id) {
        await ref.read(activeVehicleIdProvider.notifier).set(null);
      }
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
    }
    state = result;
    return !result.hasError;
  }

  Future<bool> updateMileage(
    String vehicleId,
    int mileage, {
    String source = 'manual',
  }) async {
    final result = await AsyncValue.guard(
      () => _repo.updateMileage(vehicleId, mileage, source: source),
    );
    if (!result.hasError) {
      ref.invalidate(vehiclesProvider);
      ref.invalidate(activeVehicleProvider);
      ref.invalidate(activeVehicleMileageLogsProvider);
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
