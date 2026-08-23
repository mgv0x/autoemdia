import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/reminder_entity.dart';

/// DTO com serialização do Firestore para ReminderEntity.
class ReminderModel extends ReminderEntity {
  const ReminderModel({
    required super.id,
    required super.vehicleId,
    required super.title,
    super.category,
    super.dueDate,
    super.dueMileage,
    super.completed,
    super.notificationEnabled,
    super.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      ReminderModel(
        id: id ?? (json['id'] as String),
        vehicleId: json['vehicle_id'] as String,
        title: json['title'] as String,
        category: json['category'] as String?,
        dueDate: _toDate(json['due_date']),
        dueMileage: (json['due_mileage'] as num?)?.toInt(),
        completed: (json['completed'] as bool?) ?? false,
        notificationEnabled: (json['notification_enabled'] as bool?) ?? true,
        createdAt: _toDate(json['created_at']),
      );

  static Map<String, dynamic> toJson(ReminderEntity e) => {
    'vehicle_id': e.vehicleId,
    'title': e.title,
    'category': e.category,
    'due_date': e.dueDate == null ? null : _d(e.dueDate!),
    'due_mileage': e.dueMileage,
    'completed': e.completed,
    'notification_enabled': e.notificationEnabled,
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
