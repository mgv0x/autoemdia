import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/vehicle_entity.dart';
import '../domain/vehicle_type.dart';

/// DTO com serialização do Firestore para VehicleEntity.
class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.userId,
    super.type = VehicleType.car,
    required super.brand,
    required super.model,
    super.version,
    required super.year,
    required super.fuel,
    super.plate,
    super.currentMileage,
    super.initialMileage,
    super.engine,
    super.displacement,
    super.notes,
    super.photoPath,
    super.createdAt,
    super.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      VehicleModel(
        id: id ?? (json['id'] as String?) ?? '',
        userId: (json['user_id'] as String?) ?? '',
        type: VehicleType.fromString(json['type'] as String?),
        brand: (json['brand'] as String?) ?? '',
        model: (json['model'] as String?) ?? '',
        version: json['version'] as String?,
        year: (json['year'] as num?)?.toInt() ?? 0,
        fuel: (json['fuel'] as String?) ?? '',
        plate: json['plate'] as String?,
        currentMileage: (json['current_mileage'] as num?)?.toInt() ?? 0,
        initialMileage:
            (json['initial_mileage'] as num?)?.toInt() ??
            (json['current_mileage'] as num?)?.toInt() ??
            0,
        engine: json['engine'] as String?,
        displacement: (json['displacement'] as num?)?.toInt(),
        notes: json['notes'] as String?,
        photoPath: json['photo_path'] as String?,
        createdAt: _toDateTime(json['created_at']),
        updatedAt: _toDateTime(json['updated_at']),
      );

  static Map<String, dynamic> toJson(
    VehicleEntity vehicle, {
    required String userId,
  }) => {
    'user_id': userId,
    'type': vehicle.type.name,
    'brand': vehicle.brand,
    'model': vehicle.model,
    'version': vehicle.version,
    'year': vehicle.year,
    'fuel': vehicle.fuel,
    'plate': vehicle.plate,
    'current_mileage': vehicle.currentMileage,
    'initial_mileage': vehicle.initialMileage,
    'engine': vehicle.engine,
    'displacement': vehicle.displacement,
    'notes': vehicle.notes,
    'photo_path': vehicle.photoPath,
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
