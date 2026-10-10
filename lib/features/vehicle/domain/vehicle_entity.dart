import 'vehicle_type.dart';

/// Entidade de domínio: Veículo (Carro ou Moto).
class VehicleEntity {
  const VehicleEntity({
    required this.id,
    required this.userId,
    this.type = VehicleType.car,
    required this.brand,
    required this.model,
    this.version,
    required this.year,
    required this.fuel,
    this.plate,
    this.currentMileage = 0,
    this.initialMileage = 0,
    this.engine,
    this.displacement,
    this.notes,
    this.photoPath, // caminho local do arquivo (não é URL)
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final VehicleType type;
  final String brand;
  final String model;
  final String? version;
  final int year;
  final String fuel;
  final String? plate;
  final int currentMileage;
  final int initialMileage;
  final String? engine;
  final int? displacement; // cilindrada (moto)
  final String? notes;

  /// Caminho local (ex.: /data/user/0/com.autoemdia.app/...). Persistido
  /// no Firestore como referência de preview local apenas (sem upload).
  final String? photoPath;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isMotorcycle => type == VehicleType.motorcycle;
  bool get isCar => type == VehicleType.car;

  String get displayName =>
      version != null && version!.isNotEmpty
          ? '$brand $model $version $year'
          : '$brand $model $year';

  VehicleEntity copyWith({
    String? id,
    VehicleType? type,
    String? brand,
    String? model,
    String? version,
    int? year,
    String? fuel,
    String? plate,
    int? currentMileage,
    int? initialMileage,
    String? engine,
    int? displacement,
    String? notes,
    String? photoPath,
    DateTime? updatedAt,
  }) => VehicleEntity(
    id: id ?? this.id,
    userId: userId,
    type: type ?? this.type,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    version: version ?? this.version,
    year: year ?? this.year,
    fuel: fuel ?? this.fuel,
    plate: plate ?? this.plate,
    currentMileage: currentMileage ?? this.currentMileage,
    initialMileage: initialMileage ?? this.initialMileage,
    engine: engine ?? this.engine,
    displacement: displacement ?? this.displacement,
    notes: notes ?? this.notes,
    photoPath: photoPath ?? this.photoPath,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
