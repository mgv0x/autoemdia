import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/reminder_entity.dart';

/// DTO com serialização do Firestore para ReminderEntity.
class ReminderModel extends ReminderEntity {
  const ReminderModel({
    required super.id,
    required super.vehicleId,
    required super.title,
    super.category,
    super.type = ReminderType.mileage,
    super.dueDate,
    super.dueMileage,
    super.recurrenceKm,
    super.recurrenceDays,
    super.leadKm = 500,
    super.leadDays = 30,
    super.completed = false,
    super.completedAt,
    super.notificationEnabled = true,
    super.sourceMaintenanceId,
    super.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      ReminderModel(
        id: id ?? (json['id'] as String?) ?? '',
        vehicleId: (json['vehicle_id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        category: json['category'] as String?,
        type: ReminderType.fromString(json['type'] as String?),
        dueDate: _toDate(json['due_date']),
        dueMileage: (json['due_mileage'] as num?)?.toInt(),
        recurrenceKm: (json['recurrence_km'] as num?)?.toInt(),
        recurrenceDays: (json['recurrence_days'] as num?)?.toInt(),
        leadKm: (json['lead_km'] as num?)?.toInt() ?? 500,
        leadDays: (json['lead_days'] as num?)?.toInt() ?? 30,
        completed: (json['completed'] as bool?) ?? false,
        completedAt: _toDate(json['completed_at']),
        notificationEnabled: (json['notification_enabled'] as bool?) ?? true,
        sourceMaintenanceId: json['source_maintenance_id'] as String?,
        createdAt: _toDate(json['created_at']),
      );

  static Map<String, dynamic> toJson(ReminderEntity e) => {
    'vehicle_id': e.vehicleId,
    'title': e.title,
    'category': e.category,
    'type': e.type.name,
    'due_date': e.dueDate == null ? null : _d(e.dueDate!),
    'due_mileage': e.dueMileage,
    'recurrence_km': e.recurrenceKm,
    'recurrence_days': e.recurrenceDays,
    'lead_km': e.leadKm,
    'lead_days': e.leadDays,
    'completed': e.completed,
    'completed_at': e.completedAt == null ? null : _d(e.completedAt!),
    'notification_enabled': e.notificationEnabled,
    'source_maintenance_id': e.sourceMaintenanceId,
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
