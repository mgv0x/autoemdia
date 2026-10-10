import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/mileage_log_entity.dart';

class MileageLogModel extends MileageLogEntity {
  const MileageLogModel({
    required super.id,
    required super.vehicleId,
    required super.mileage,
    required super.date,
    super.source = 'manual',
    super.createdAt,
  });

  factory MileageLogModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      MileageLogModel(
        id: id ?? (json['id'] as String?) ?? '',
        vehicleId: (json['vehicle_id'] as String?) ?? '',
        mileage: (json['mileage'] as num?)?.toInt() ?? 0,
        date: _toDate(json['date']) ?? DateTime.now(),
        source: (json['source'] as String?) ?? 'manual',
        createdAt: _toDate(json['created_at']),
      );

  static Map<String, dynamic> toJson(MileageLogEntity log) => {
    'vehicle_id': log.vehicleId,
    'mileage': log.mileage,
    'date':
        '${log.date.year.toString().padLeft(4, '0')}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}',
    'source': log.source,
    'created_at': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
