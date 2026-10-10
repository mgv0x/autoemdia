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

  /// Conclui um lembrete e, caso seja recorrente, agenda o próximo ciclo automaticamente.
  Future<bool> complete(
    String id, {
    ReminderEntity? reminder,
    int? executionMileage,
  }) async {
    final result = await AsyncValue.guard(() async {
      await _repo.setCompleted(id, true);
      await cancelReminderNotifications(id);

      // Se for recorrente, gera automaticamente o próximo ciclo
      if (reminder != null && reminder.isRecurring) {
        final now = DateTime.now();
        DateTime? nextDueDate;
        if (reminder.recurrenceDays != null && reminder.recurrenceDays! > 0) {
          nextDueDate = now.add(Duration(days: reminder.recurrenceDays!));
        }

        int? nextDueMileage;
        if (reminder.recurrenceKm != null && reminder.recurrenceKm! > 0) {
          final baseKm = executionMileage ?? reminder.dueMileage ?? 0;
          nextDueMileage = baseKm + reminder.recurrenceKm!;
        }

        final nextReminder = ReminderEntity(
          id: '',
          vehicleId: reminder.vehicleId,
          title: reminder.title,
          category: reminder.category,
          type: reminder.type,
          dueDate: nextDueDate,
          dueMileage: nextDueMileage,
          recurrenceKm: reminder.recurrenceKm,
          recurrenceDays: reminder.recurrenceDays,
          leadKm: reminder.leadKm,
          leadDays: reminder.leadDays,
          completed: false,
          notificationEnabled: reminder.notificationEnabled,
          sourceMaintenanceId: reminder.sourceMaintenanceId,
        );

        final created = await _repo.create(nextReminder);
        if (created.notificationEnabled) {
          await scheduleReminderNotifications(created);
        }
      }
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
