import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../vehicle/presentation/controllers/vehicle_controller.dart';
import '../../data/firestore_reminder_repository.dart';
import '../../domain/reminder_entity.dart';
import '../../domain/reminder_repository.dart';
import '../../domain/reminder_scheduler.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return FirestoreReminderRepository(ref.watch(firestoreProvider));
});

final remindersProvider = FutureProvider<List<ReminderEntity>>((ref) async {
  final vehicle = await ref.watch(activeVehicleProvider.future);
  if (vehicle == null) return <ReminderEntity>[];
  return ref.watch(reminderRepositoryProvider).getByVehicle(vehicle.id);
});

class ReminderController extends Notifier<AsyncValue<ReminderEntity?>> {
  @override
  AsyncValue<ReminderEntity?> build() => const AsyncData(null);

  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);

  Future<ReminderEntity?> create(ReminderEntity e) => _run(() async {
    final created = await _repo.create(e);
    await scheduleReminderNotifications(created);
    return created;
  });

  Future<ReminderEntity?> update(ReminderEntity e) => _run(() async {
    final updated = await _repo.update(e);
    await scheduleReminderNotifications(updated);
    return updated;
  });

  Future<ReminderEntity?> _run(Future<ReminderEntity> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!result.hasError) ref.invalidate(remindersProvider);
    state = result;
    return result.value;
  }

  Future<bool> delete(ReminderEntity e) async {
    final result = await AsyncValue.guard(() async {
      await cancelReminderNotifications(e.id);
      await _repo.delete(e.id);
      return null;
    });
    if (!result.hasError) ref.invalidate(remindersProvider);
    return !result.hasError;
  }

  Future<bool> complete(String id) async {
    final result = await AsyncValue.guard(() async {
      await _repo.setCompleted(id, true);
      await cancelReminderNotifications(id);
      return null;
    });
    if (!result.hasError) ref.invalidate(remindersProvider);
    return !result.hasError;
  }

  Future<bool> setNotificationEnabled(ReminderEntity e, bool enabled) async {
    final result = await AsyncValue.guard(() async {
      await _repo.setNotificationEnabled(e.id, enabled);
      if (enabled && !e.completed) {
        await scheduleReminderNotifications(
          e.copyWith(notificationEnabled: true),
        );
      } else {
        await cancelReminderNotifications(e.id);
      }
      return null;
    });
    if (!result.hasError) ref.invalidate(remindersProvider);
    return !result.hasError;
  }
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, AsyncValue<ReminderEntity?>>(
      ReminderController.new,
    );
