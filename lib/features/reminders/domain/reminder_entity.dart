/// Tipo de agendamento do lembrete.
enum ReminderType {
  mileage,
  date,
  recurring;

  static ReminderType fromString(String? value) {
    return switch (value?.toLowerCase().trim()) {
      'recurring' || 'recorrente' => ReminderType.recurring,
      'date' || 'data' => ReminderType.date,
      _ => ReminderType.mileage,
    };
  }
}

/// Estado de um cuidado automotivo com base na urgência.
enum CareStatus {
  overdue,   // Atrasado: km vencida ou data ultrapassada
  upcoming,  // Próximo: dentro da antecedência configurada (leadKm / leadDays)
  upToDate,  // Em dia: com vencimento futuro além da antecedência
  completed, // Concluído
}

/// Entidade de domínio: Lembrete / Próximo cuidado.
class ReminderEntity {
  const ReminderEntity({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.category,
    this.type = ReminderType.mileage,
    this.dueDate,
    this.dueMileage,
    this.recurrenceKm,
    this.recurrenceDays,
    this.leadKm = 500,
    this.leadDays = 30,
    this.completed = false,
    this.completedAt,
    this.notificationEnabled = true,
    this.sourceMaintenanceId,
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String title;
  final String? category;
  final ReminderType type;
  final DateTime? dueDate;
  final int? dueMileage;
  final int? recurrenceKm;
  final int? recurrenceDays;
  final int leadKm;
  final int leadDays;
  final bool completed;
  final DateTime? completedAt;
  final bool notificationEnabled;
  final String? sourceMaintenanceId;
  final DateTime? createdAt;

  bool get isRecurring =>
      type == ReminderType.recurring ||
      (recurrenceKm != null && recurrenceKm! > 0) ||
      (recurrenceDays != null && recurrenceDays! > 0);

  /// Calcula o estado do cuidado (pior estado entre km e data).
  CareStatus calculateStatus(int currentMileage, [DateTime? today]) {
    if (completed) return CareStatus.completed;

    final now = today ?? DateTime.now();
    final todayClean = DateTime(now.year, now.month, now.day);

    bool isOverdue = false;
    bool isUpcoming = false;

    // 1. Verificação por data
    if (dueDate != null) {
      final dueClean = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      final daysDiff = dueClean.difference(todayClean).inDays;
      if (daysDiff < 0) {
        isOverdue = true;
      } else if (daysDiff <= leadDays) {
        isUpcoming = true;
      }
    }

    // 2. Verificação por quilometragem
    if (dueMileage != null) {
      final kmDiff = dueMileage! - currentMileage;
      if (kmDiff <= 0) {
        isOverdue = true;
      } else if (kmDiff <= leadKm) {
        isUpcoming = true;
      }
    }

    // Vale o pior estado: atrasado > próximo > em dia
    if (isOverdue) return CareStatus.overdue;
    if (isUpcoming) return CareStatus.upcoming;
    return CareStatus.upToDate;
  }

  ReminderEntity copyWith({
    String? id,
    String? title,
    String? category,
    ReminderType? type,
    DateTime? dueDate,
    int? dueMileage,
    int? recurrenceKm,
    int? recurrenceDays,
    int? leadKm,
    int? leadDays,
    bool? completed,
    DateTime? completedAt,
    bool? notificationEnabled,
    String? sourceMaintenanceId,
  }) => ReminderEntity(
    id: id ?? this.id,
    vehicleId: vehicleId,
    title: title ?? this.title,
    category: category ?? this.category,
    type: type ?? this.type,
    dueDate: dueDate ?? this.dueDate,
    dueMileage: dueMileage ?? this.dueMileage,
    recurrenceKm: recurrenceKm ?? this.recurrenceKm,
    recurrenceDays: recurrenceDays ?? this.recurrenceDays,
    leadKm: leadKm ?? this.leadKm,
    leadDays: leadDays ?? this.leadDays,
    completed: completed ?? this.completed,
    completedAt: completedAt ?? this.completedAt,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    sourceMaintenanceId: sourceMaintenanceId ?? this.sourceMaintenanceId,
    createdAt: createdAt,
  );
}
