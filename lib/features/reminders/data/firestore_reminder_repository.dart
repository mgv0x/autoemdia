import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../domain/reminder_entity.dart';
import '../domain/reminder_repository.dart';
import 'reminder_model.dart';

class FirestoreReminderRepository implements ReminderRepository {
  FirestoreReminderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reminders');

  @override
  Future<List<ReminderEntity>> getByVehicle(String vehicleId) async {
    try {
      final snap = await _col
          .where('vehicle_id', isEqualTo: vehicleId)
          .orderBy('due_date')
          .get();
      return snap.docs
          .map((d) => ReminderModel.fromJson(d.data(), id: d.id))
          .toList();
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar os lembretes.');
    }
  }

  @override
  Future<ReminderEntity> create(ReminderEntity entity) async {
    try {
      final ref = _col.doc();
      await ref.set(ReminderModel.toJson(entity));
      final created = await ref.get();
      return ReminderModel.fromJson(created.data()!, id: ref.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível criar o lembrete.');
    }
  }

  @override
  Future<ReminderEntity> update(ReminderEntity entity) async {
    try {
      await _col
          .doc(entity.id)
          .set(ReminderModel.toJson(entity), SetOptions(merge: true));
      final updated = await _col.doc(entity.id).get();
      return ReminderModel.fromJson(updated.data()!, id: entity.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar o lembrete.');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir o lembrete.');
    }
  }

  @override
  Future<void> setCompleted(String id, bool completed) async {
    try {
      await _col.doc(id).set({'completed': completed}, SetOptions(merge: true));
    } catch (e) {
      throw handleError(e, 'Não foi possível concluir o lembrete.');
    }
  }

  @override
  Future<void> setNotificationEnabled(String id, bool enabled) async {
    try {
      await _col.doc(id).set({
        'notification_enabled': enabled,
      }, SetOptions(merge: true));
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar o lembrete.');
    }
  }
}
