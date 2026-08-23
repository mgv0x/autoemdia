import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/expense_entity.dart';

/// DTO com serialização do Firestore para ExpenseEntity.
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.vehicleId,
    required super.category,
    required super.description,
    required super.amount,
    required super.expenseDate,
    super.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      ExpenseModel(
        id: id ?? (json['id'] as String),
        vehicleId: json['vehicle_id'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        expenseDate: _toDate(json['expense_date']) ?? DateTime.now(),
        createdAt: _toDate(json['created_at']),
      );

  static Map<String, dynamic> toJson(ExpenseEntity e) => {
    'vehicle_id': e.vehicleId,
    'category': e.category,
    'description': e.description,
    'amount': e.amount,
    'expense_date': _d(e.expenseDate),
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
