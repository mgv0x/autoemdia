import 'mileage_log_entity.dart';
import 'vehicle_entity.dart';

abstract interface class VehicleRepository {
  Future<List<VehicleEntity>> getVehicles();
  Future<VehicleEntity?> getVehicleById(String id);
  Future<VehicleEntity> createVehicle(VehicleEntity vehicle);
  Future<VehicleEntity> updateVehicle(VehicleEntity vehicle);
  Future<void> deleteVehicle(String id);
  Future<void> updateMileage(String vehicleId, int mileage, {String source = 'manual'});
  Future<void> logMileage({
    required String vehicleId,
    required int mileage,
    required DateTime date,
    String source = 'manual',
  });
  Future<List<MileageLogEntity>> getMileageLogs(String vehicleId);
}
