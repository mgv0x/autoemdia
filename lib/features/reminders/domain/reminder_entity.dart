/// Entidade de domínio: lembrete.
class ReminderEntity {
  const ReminderEntity({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.category,
    this.dueDate,
    this.dueMileage,
    this.completed = false,
    this.notificationEnabled = true,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String title;
  final String? category;
  final DateTime? dueDate;
  final int? dueMileage;
  final bool completed;
  final bool notificationEnabled;
  final DateTime? createdAt;

  ReminderEntity copyWith({
    String? title,
    String? category,
    DateTime? dueDate,
    int? dueMileage,
    bool? completed,
    bool? notificationEnabled,
  }) => ReminderEntity(
    id: id,
    vehicleId: vehicleId,
    title: title ?? this.title,
    category: category ?? this.category,
    dueDate: dueDate ?? this.dueDate,
    dueMileage: dueMileage ?? this.dueMileage,
    completed: completed ?? this.completed,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    createdAt: createdAt,
  );
}

/// Classificação do lembrete para agrupamento na UI.
enum ReminderStatus { overdue, upcoming, future, completed }
