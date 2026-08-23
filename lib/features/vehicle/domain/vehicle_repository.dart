import 'vehicle_entity.dart';

abstract interface class VehicleRepository {
  Future<List<VehicleEntity>> getVehicles();
  Future<VehicleEntity?> getVehicleById(String id);
  Future<VehicleEntity> createVehicle(VehicleEntity vehicle);
  Future<VehicleEntity> updateVehicle(VehicleEntity vehicle);
  Future<void> deleteVehicle(String id);
  Future<void> updateMileage(String vehicleId, int mileage);
}
