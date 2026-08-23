import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/error_mapper.dart';
import '../domain/vehicle_entity.dart';
import '../domain/vehicle_repository.dart';
import 'vehicle_model.dart';

/// Implementação do [VehicleRepository] com Cloud Firestore.
class FirestoreVehicleRepository implements VehicleRepository {
  FirestoreVehicleRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _db.collection('vehicles');

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<VehicleEntity>> getVehicles() async {
    try {
      final snapshot = await _vehicles
          .where('user_id', isEqualTo: _uid)
          .orderBy('created_at')
          .get();
      return snapshot.docs
          .map((d) => VehicleModel.fromJson(d.data(), id: d.id))
          .toList();
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar seus veículos.');
    }
  }

  @override
  Future<VehicleEntity?> getVehicleById(String id) async {
    try {
      final doc = await _vehicles.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['user_id'] != _uid) return null;
      return VehicleModel.fromJson(data, id: doc.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar o veículo.');
    }
  }

  @override
  Future<VehicleEntity> createVehicle(VehicleEntity vehicle) async {
    try {
      final payload = VehicleModel.toJson(vehicle, userId: _uid!);
      final ref = _vehicles.doc();
      await ref.set(payload..['created_at'] = FieldValue.serverTimestamp());
      final created = await ref.get();
      return VehicleModel.fromJson(created.data()!, id: ref.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível cadastrar o veículo.');
    }
  }

  @override
  Future<VehicleEntity> updateVehicle(VehicleEntity vehicle) async {
    try {
      final payload = VehicleModel.toJson(vehicle, userId: _uid!)
        ..['updated_at'] = FieldValue.serverTimestamp();
      await _vehicles.doc(vehicle.id).set(payload, SetOptions(merge: true));
      final updated = await _vehicles.doc(vehicle.id).get();
      return VehicleModel.fromJson(updated.data()!, id: vehicle.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar o veículo.');
    }
  }

  @override
  Future<void> deleteVehicle(String id) async {
    try {
      await _vehicles.doc(id).delete();
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir o veículo.');
    }
  }

  @override
  Future<void> updateMileage(String vehicleId, int mileage) async {
    try {
      await _vehicles.doc(vehicleId).set({
        'current_mileage': mileage,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar a quilometragem.');
    }
  }
}
