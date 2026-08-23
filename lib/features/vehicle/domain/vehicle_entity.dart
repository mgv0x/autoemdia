/// Entidade de domínio: Veículo.
class VehicleEntity {
  const VehicleEntity({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    this.plate,
    this.currentMileage = 0,
    this.photoPath, // caminho local do arquivo (não é URL)
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final String fuel;
  final String? plate;
  final int currentMileage;

  /// Caminho local (ex.: /data/user/0/com.autoemdia.app/...). Persistido
  /// no Firestore como referência de preview local apenas (sem upload).
  final String? photoPath;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => '$brand $model $year';

  VehicleEntity copyWith({
    String? brand,
    String? model,
    int? year,
    String? fuel,
    String? plate,
    int? currentMileage,
    String? photoPath,
    DateTime? updatedAt,
  }) => VehicleEntity(
    id: id,
    userId: userId,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    year: year ?? this.year,
    fuel: fuel ?? this.fuel,
    plate: plate ?? this.plate,
    currentMileage: currentMileage ?? this.currentMileage,
    photoPath: photoPath ?? this.photoPath,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
