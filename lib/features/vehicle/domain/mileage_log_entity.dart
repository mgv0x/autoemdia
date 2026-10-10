/// Registro histórico de quilometragem para alimentar média de km/dia
/// e estimativas de vencimentos.
class MileageLogEntity {
  const MileageLogEntity({
    required this.id,
    required this.vehicleId,
    required this.mileage,
    required this.date,
    this.source = 'manual', // 'manual' | 'maintenance' | 'expense'
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final int mileage;
  final DateTime date;
  final String source;
  final DateTime? createdAt;
}
