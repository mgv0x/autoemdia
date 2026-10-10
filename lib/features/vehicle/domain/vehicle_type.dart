import 'package:flutter/material.dart';

/// Tipo de veículo suportado pelo Auto em Dia.
enum VehicleType {
  car,
  motorcycle;

  String get id => name;

  String get label => switch (this) {
    VehicleType.car => 'Carro',
    VehicleType.motorcycle => 'Moto',
  };

  IconData get icon => switch (this) {
    VehicleType.car => Icons.directions_car_rounded,
    VehicleType.motorcycle => Icons.two_wheeler_rounded,
  };

  IconData get outlineIcon => switch (this) {
    VehicleType.car => Icons.directions_car_outlined,
    VehicleType.motorcycle => Icons.two_wheeler_outlined,
  };

  static VehicleType fromString(String? value) {
    if (value == null) return VehicleType.car;
    return switch (value.toLowerCase().trim()) {
      'motorcycle' || 'moto' => VehicleType.motorcycle,
      _ => VehicleType.car,
    };
  }
}
