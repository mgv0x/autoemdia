/// Entidade de domínio: despesa/gasto.
class ExpenseEntity {
  const ExpenseEntity({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String category;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final DateTime? createdAt;

  ExpenseEntity copyWith({
    String? id,
    String? vehicleId,
    String? category,
    String? description,
    double? amount,
    DateTime? expenseDate,
    DateTime? createdAt,
  }) => ExpenseEntity(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    category: category ?? this.category,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    expenseDate: expenseDate ?? this.expenseDate,
    createdAt: createdAt ?? this.createdAt,
  );
}
