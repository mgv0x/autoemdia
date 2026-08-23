import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository.dart';
import 'expense_model.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('expenses');

  @override
  Future<List<ExpenseEntity>> getByVehicle(String vehicleId) async {
    try {
      final snap = await _col
          .where('vehicle_id', isEqualTo: vehicleId)
          .orderBy('expense_date', descending: true)
          .get();
      return snap.docs
          .map((d) => ExpenseModel.fromJson(d.data(), id: d.id))
          .toList();
    } catch (e) {
      throw handleError(e, 'Não foi possível carregar os gastos.');
    }
  }

  @override
  Future<ExpenseEntity> create(ExpenseEntity entity) async {
    try {
      final ref = _col.doc();
      await ref.set(ExpenseModel.toJson(entity));
      final created = await ref.get();
      return ExpenseModel.fromJson(created.data()!, id: ref.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível salvar o gasto.');
    }
  }

  @override
  Future<ExpenseEntity> update(ExpenseEntity entity) async {
    try {
      await _col
          .doc(entity.id)
          .set(ExpenseModel.toJson(entity), SetOptions(merge: true));
      final updated = await _col.doc(entity.id).get();
      return ExpenseModel.fromJson(updated.data()!, id: entity.id);
    } catch (e) {
      throw handleError(e, 'Não foi possível atualizar o gasto.');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir o gasto.');
    }
  }
}
