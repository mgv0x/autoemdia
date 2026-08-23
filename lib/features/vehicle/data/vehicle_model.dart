import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/vehicle_entity.dart';

/// DTO com serialização do Firestore para VehicleEntity.
class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.userId,
    required super.brand,
    required super.model,
    required super.year,
    required super.fuel,
    super.plate,
    super.currentMileage,
    super.photoPath,
    super.createdAt,
    super.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      VehicleModel(
        id: id ?? (json['id'] as String),
        userId: json['user_id'] as String,
        brand: (json['brand'] as String?) ?? '',
        model: (json['model'] as String?) ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        fuel: (json['fuel'] as String?) ?? '',
        plate: json['plate'] as String?,
        currentMileage: (json['current_mileage'] as num?)?.toInt() ?? 0,
        photoPath: json['photo_path'] as String?,
        createdAt: _toDateTime(json['created_at']),
        updatedAt: _toDateTime(json['updated_at']),
      );

  static Map<String, dynamic> toJson(
    VehicleEntity vehicle, {
    required String userId,
  }) => {
    'user_id': userId,
    'brand': vehicle.brand,
    'model': vehicle.model,
    'year': vehicle.year,
    'fuel': vehicle.fuel,
    'plate': vehicle.plate,
    'current_mileage': vehicle.currentMileage,
    'photo_path': vehicle.photoPath,
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
