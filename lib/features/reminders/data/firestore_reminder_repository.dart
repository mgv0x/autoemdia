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
          .get();
      final list = snap.docs
          .map((d) => ReminderModel.fromJson(d.data(), id: d.id))
          .toList();
      list.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return list;
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar os lembretes.');
    }
  }

  @override
  Future<ReminderEntity> create(ReminderEntity entity) async {
    try {
      final ref = entity.id.isNotEmpty ? _col.doc(entity.id) : _col.doc();
      await ref.set(ReminderModel.toJson(entity));
      return entity.copyWith(id: ref.id);
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
      return entity;
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
      await _col.doc(id).set({
        'completed': completed,
        'completed_at': completed ? FieldValue.serverTimestamp() : null,
      }, SetOptions(merge: true));
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
