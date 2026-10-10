import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/error_mapper.dart';
import '../domain/mileage_log_entity.dart';
import '../domain/vehicle_entity.dart';
import '../domain/vehicle_repository.dart';
import 'mileage_log_model.dart';
import 'vehicle_model.dart';

/// Implementação do [VehicleRepository] com Cloud Firestore.
/// Suporta persistência de múltiplos veículos, histórico de km e exclusão em cascata.
class FirestoreVehicleRepository implements VehicleRepository {
  FirestoreVehicleRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _db.collection('vehicles');

  CollectionReference<Map<String, dynamic>> get _mileageLogs =>
      _db.collection('mileage_logs');

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<VehicleEntity>> getVehicles() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snapshot = await _vehicles
          .where('user_id', isEqualTo: uid)
          .get();
      final list = snapshot.docs
          .map((d) => VehicleModel.fromJson(d.data(), id: d.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });
      return list;
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
      final ref = vehicle.id.isNotEmpty
          ? _vehicles.doc(vehicle.id)
          : _vehicles.doc();
      await ref.set(payload..['created_at'] = FieldValue.serverTimestamp());

      // Registra a quilometragem inicial no histórico se for informada
      if (vehicle.currentMileage > 0) {
        await logMileage(
          vehicleId: ref.id,
          mileage: vehicle.currentMileage,
          date: DateTime.now(),
          source: 'manual',
        );
      }

      return vehicle.copyWith(id: ref.id);
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
      return vehicle;
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar o veículo.');
    }
  }

  /// Exclui o veículo e remove em CASCATA todas as entidades filhas vinculadas.
  /// Exclui o veículo e remove em CASCATA todas as entidades filhas vinculadas.
  @override
  Future<void> deleteVehicle(String id) async {
    try {
      // 1. Exclui coleções filhas enquanto o veículo ainda existe (satisfaz regras de segurança)
      final collections = [
        'maintenance_records',
        'expenses',
        'reminders',
        'mileage_logs',
      ];

      for (final colName in collections) {
        try {
          final snap = await _db
              .collection(colName)
              .where('vehicle_id', isEqualTo: id)
              .get();
          if (snap.docs.isNotEmpty) {
            final childBatch = _db.batch();
            for (final doc in snap.docs) {
              childBatch.delete(doc.reference);
            }
            await childBatch.commit();
          }
        } catch (_) {
          // Não impede a exclusão do veículo se uma subcoleção falhar ou estiver vazia
        }
      }

      // 2. Exclui o documento principal do veículo
      await _vehicles.doc(id).delete();
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir o veículo e seus dados.');
    }
  }

  @override
  Future<void> updateMileage(
    String vehicleId,
    int mileage, {
    String source = 'manual',
  }) async {
    try {
      final vehicleDoc = await _vehicles.doc(vehicleId).get();
      final current = (vehicleDoc.data()?['current_mileage'] as num?)?.toInt() ?? 0;

      // Só atualiza a km principal do veículo se for maior ou igual à atual
      if (mileage >= current) {
        await _vehicles.doc(vehicleId).set({
          'current_mileage': mileage,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Sempre adiciona log no histórico para alimentar a média de km/dia
      await logMileage(
        vehicleId: vehicleId,
        mileage: mileage,
        date: DateTime.now(),
        source: source,
      );
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar a quilometragem.');
    }
  }

  @override
  Future<void> logMileage({
    required String vehicleId,
    required int mileage,
    required DateTime date,
    String source = 'manual',
  }) async {
    try {
      final log = MileageLogEntity(
        id: '',
        vehicleId: vehicleId,
        mileage: mileage,
        date: date,
        source: source,
      );
      await _mileageLogs.add(MileageLogModel.toJson(log));
    } catch (e) {
      // Falha no log não deve travar operações principais
    }
  }

  @override
  Future<List<MileageLogEntity>> getMileageLogs(String vehicleId) async {
    try {
      final snap = await _mileageLogs
          .where('vehicle_id', isEqualTo: vehicleId)
          .get();
      final list = snap.docs
          .map((d) => MileageLogModel.fromJson(d.data(), id: d.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }
}
