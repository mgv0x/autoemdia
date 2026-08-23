import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../domain/maintenance_entity.dart';
import '../domain/maintenance_repository.dart';
import 'maintenance_model.dart';

class FirestoreMaintenanceRepository implements MaintenanceRepository {
  FirestoreMaintenanceRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('maintenance_records');

  @override
  Future<List<MaintenanceEntity>> getByVehicle(String vehicleId) async {
    try {
      final snap = await _col
          .where('vehicle_id', isEqualTo: vehicleId)
          .orderBy('service_date', descending: true)
          .get();
      return snap.docs
          .map((d) => MaintenanceModel.fromJson(d.data(), id: d.id))
          .toList();
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar as manutenções.');
    }
  }

  @override
  Future<MaintenanceEntity> create(MaintenanceEntity entity) async {
    try {
      final ref = _col.doc();
      await ref.set(MaintenanceModel.toJson(entity));
      final created = await ref.get();
      return MaintenanceModel.fromJson(created.data()!, id: ref.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível salvar a manutenção.');
    }
  }

  @override
  Future<MaintenanceEntity> update(MaintenanceEntity entity) async {
    try {
      await _col
          .doc(entity.id)
          .set(MaintenanceModel.toJson(entity), SetOptions(merge: true));
      final updated = await _col.doc(entity.id).get();
      return MaintenanceModel.fromJson(updated.data()!, id: entity.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar a manutenção.');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir a manutenção.');
    }
  }
}
