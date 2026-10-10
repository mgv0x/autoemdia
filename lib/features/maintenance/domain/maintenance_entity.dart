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
    this.part,
    this.workshop,
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
  final String? part; // Marca / Peça / Componente (ex.: Óleo Motul 5W30)
  final String? workshop; // Oficina / Prestador (ex.: Auto Mecânica Silva)
  final String? notes;
  final int? nextMileage;
  final DateTime? nextDate;
  final DateTime? createdAt;

  MaintenanceEntity copyWith({
    String? id,
    String? category,
    String? description,
    DateTime? serviceDate,
    int? mileage,
    double? cost,
    String? part,
    String? workshop,
    String? notes,
    int? nextMileage,
    DateTime? nextDate,
  }) => MaintenanceEntity(
    id: id ?? this.id,
    vehicleId: vehicleId,
    category: category ?? this.category,
    description: description ?? this.description,
    serviceDate: serviceDate ?? this.serviceDate,
    mileage: mileage ?? this.mileage,
    cost: cost ?? this.cost,
    part: part ?? this.part,
    workshop: workshop ?? this.workshop,
    notes: notes ?? this.notes,
    nextMileage: nextMileage ?? this.nextMileage,
    nextDate: nextDate ?? this.nextDate,
    createdAt: createdAt,
  );
}
