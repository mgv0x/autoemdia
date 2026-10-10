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
          .get();
      final list = snap.docs
          .map((d) => MaintenanceModel.fromJson(d.data(), id: d.id))
          .toList();
      list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      return list;
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar as manutenções.');
    }
  }

  @override
  Future<MaintenanceEntity> create(MaintenanceEntity entity) async {
    try {
      final ref = entity.id.isNotEmpty ? _col.doc(entity.id) : _col.doc();
      await ref.set(MaintenanceModel.toJson(entity));
      return entity.copyWith(id: ref.id);
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
      return entity;
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
