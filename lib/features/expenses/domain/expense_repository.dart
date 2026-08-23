import '../domain/expense_entity.dart';

abstract interface class ExpenseRepository {
  Future<List<ExpenseEntity>> getByVehicle(String vehicleId);
  Future<ExpenseEntity> create(ExpenseEntity entity);
  Future<ExpenseEntity> update(ExpenseEntity entity);
  Future<void> delete(String id);
}
