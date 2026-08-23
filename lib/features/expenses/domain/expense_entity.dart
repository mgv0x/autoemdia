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
}
