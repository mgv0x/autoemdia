import '../domain/reminder_entity.dart';

abstract interface class ReminderRepository {
  Future<List<ReminderEntity>> getByVehicle(String vehicleId);
  Future<ReminderEntity> create(ReminderEntity entity);
  Future<ReminderEntity> update(ReminderEntity entity);
  Future<void> delete(String id);
  Future<void> setCompleted(String id, bool completed);
  Future<void> setNotificationEnabled(String id, bool enabled);
}
