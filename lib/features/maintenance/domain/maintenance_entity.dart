/// Entidade de domínio: registro de manutenção/serviço.
class MaintenanceEntity {
  const MaintenanceEntity({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.description,
    required this.serviceDate,
    this.mileage,
    this.cost,
    this.notes,
    this.nextMileage,
    this.nextDate,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String category;
  final String description;
  final DateTime serviceDate;
  final int? mileage;
  final double? cost;
  final String? notes;
  final int? nextMileage;
  final DateTime? nextDate;
  final DateTime? createdAt;
}
