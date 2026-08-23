import '../domain/maintenance_entity.dart';

abstract interface class MaintenanceRepository {
  Future<List<MaintenanceEntity>> getByVehicle(String vehicleId);
  Future<MaintenanceEntity> create(MaintenanceEntity entity);
  Future<MaintenanceEntity> update(MaintenanceEntity entity);
  Future<void> delete(String id);
}
