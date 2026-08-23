import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/maintenance_entity.dart';

/// DTO com serialização do Firestore para MaintenanceEntity.
class MaintenanceModel extends MaintenanceEntity {
  const MaintenanceModel({
    required super.id,
    required super.vehicleId,
    required super.category,
    required super.description,
    required super.serviceDate,
    super.mileage,
    super.cost,
    super.notes,
    super.nextMileage,
    super.nextDate,
    super.createdAt,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      MaintenanceModel(
        id: id ?? (json['id'] as String),
        vehicleId: json['vehicle_id'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        serviceDate: _toDate(json['service_date']) ?? DateTime.now(),
        mileage: (json['mileage'] as num?)?.toInt(),
        cost: (json['cost'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        nextMileage: (json['next_mileage'] as num?)?.toInt(),
        nextDate: _toDate(json['next_date']),
        createdAt: _toDate(json['created_at']),
      );

  static Map<String, dynamic> toJson(MaintenanceEntity e) => {
    'vehicle_id': e.vehicleId,
    'category': e.category,
    'description': e.description,
    'service_date': _d(e.serviceDate),
    'mileage': e.mileage,
    'cost': e.cost,
    'notes': e.notes,
    'next_mileage': e.nextMileage,
    'next_date': e.nextDate == null ? null : _d(e.nextDate!),
    'created_at': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
