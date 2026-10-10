import 'package:flutter/material.dart';

import 'vehicle_type.dart';

/// Modelo de sugestão de intervalo preventivo (apenas informativo/editável).
class MaintenanceIntervalSuggestion {
  const MaintenanceIntervalSuggestion({
    required this.title,
    required this.category,
    this.intervalKm,
    this.intervalMonths,
    this.notes,
  });

  final String title;
  final String category;
  final int? intervalKm;
  final int? intervalMonths;
  final String? notes;

  String get summary {
    final parts = <String>[];
    if (intervalKm != null) parts.add('${intervalKm!} km');
    if (intervalMonths != null) parts.add('${intervalMonths!} meses');
    return parts.isEmpty ? 'Conforme manual' : parts.join(' ou ');
  }
}

/// Configuração desacoplada por tipo de veículo (evita espalhar if/else).
class VehicleTypeConfig {
  const VehicleTypeConfig({
    required this.type,
    required this.label,
    required this.vehicleTerm,
    required this.icon,
    required this.outlineIcon,
    required this.maintenanceCategories,
    required this.expenseCategories,
    required this.fuelTypes,
    required this.showDisplacement,
    required this.showEngine,
    required this.mileageLabel,
    required this.displacementHint,
    required this.serviceDescriptionHint,
    required this.partHint,
    required this.workshopHint,
    required this.intervalSuggestions,
  });

  final VehicleType type;
  final String label;
  final String vehicleTerm; // 'carro' ou 'moto'
  final IconData icon;
  final IconData outlineIcon;
  final List<String> maintenanceCategories;
  final List<String> expenseCategories;
  final List<String> fuelTypes;
  final bool showDisplacement;
  final bool showEngine;
  final String mileageLabel;
  final String displacementHint;
  final String serviceDescriptionHint;
  final String partHint;
  final String workshopHint;
  final List<MaintenanceIntervalSuggestion> intervalSuggestions;

  bool get isMotorcycle => type == VehicleType.motorcycle;
  bool get isCar => type == VehicleType.car;

  static const carConfig = VehicleTypeConfig(
    type: VehicleType.car,
    label: 'Carro',
    vehicleTerm: 'carro',
    icon: Icons.directions_car_rounded,
    outlineIcon: Icons.directions_car_outlined,
    maintenanceCategories: [
      'Óleo e filtros',
      'Freios',
      'Pneus',
      'Suspensão',
      'Motor',
      'Elétrica',
      'Ar-condicionado',
      'Transmissão',
      'Direção',
      'Bateria',
      'Revisão',
      'Outros',
    ],
    expenseCategories: [
      'Manutenção',
      'Combustível',
      'Pneus',
      'Seguro',
      'Impostos',
      'Lavagem',
      'Acessórios',
      'Outros',
    ],
    fuelTypes: [
      'Flex',
      'Gasolina',
      'Etanol',
      'Diesel',
      'GNV',
      'Híbrido',
      'Elétrico',
    ],
    showDisplacement: false,
    showEngine: true,
    mileageLabel: 'Quilometragem (km)',
    displacementHint: '',
    serviceDescriptionHint: 'Ex.: Troca de óleo e filtro',
    partHint: 'Ex.: Filtro Mann, Óleo 5W30',
    workshopHint: 'Ex.: Auto Mecânica Silva',
    intervalSuggestions: [
      MaintenanceIntervalSuggestion(
        title: 'Troca de óleo e filtro',
        category: 'Óleo e filtros',
        intervalKm: 10000,
        intervalMonths: 6,
        notes: 'Sugestão média para óleos sintéticos. Consulte o manual.',
      ),
      MaintenanceIntervalSuggestion(
        title: 'Alinhamento e balanceamento',
        category: 'Suspensão',
        intervalKm: 10000,
        intervalMonths: 6,
        notes: 'Recomendado a cada 10.000 km ou ao trocar pneus.',
      ),
      MaintenanceIntervalSuggestion(
        title: 'Filtro de ar do motor',
        category: 'Motor',
        intervalKm: 15000,
        intervalMonths: 12,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Filtro do ar-condicionado',
        category: 'Ar-condicionado',
        intervalKm: 10000,
        intervalMonths: 6,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Pastilhas de freio',
        category: 'Freios',
        intervalKm: 20000,
        intervalMonths: 12,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Fluido de freio',
        category: 'Freios',
        intervalMonths: 24,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Revisão periódica',
        category: 'Revisão',
        intervalKm: 10000,
        intervalMonths: 12,
      ),
    ],
  );

  static const motorcycleConfig = VehicleTypeConfig(
    type: VehicleType.motorcycle,
    label: 'Moto',
    vehicleTerm: 'moto',
    icon: Icons.two_wheeler_rounded,
    outlineIcon: Icons.two_wheeler_outlined,
    maintenanceCategories: [
      'Óleo 4T',
      'Filtros',
      'Relação (corrente, pinhão e coroa)',
      'Freios',
      'Pneus',
      'Suspensão',
      'Motor',
      'Elétrica',
      'Bateria',
      'Revisão',
      'Outros',
    ],
    expenseCategories: [
      'Manutenção',
      'Combustível',
      'Pneus',
      'Seguro',
      'Impostos',
      'Lavagem',
      'Acessórios',
      'Outros',
    ],
    fuelTypes: ['Gasolina', 'Flex', 'Etanol', 'Elétrica'],
    showDisplacement: true,
    showEngine: true,
    mileageLabel: 'Quilometragem (km)',
    displacementHint: 'Ex.: 160cc, 250cc, 650cc',
    serviceDescriptionHint: 'Ex.: Lubrificação da corrente, Troca de óleo 4T',
    partHint: 'Ex.: Óleo Motul 5100 4T, Kit Relação DID',
    workshopHint: 'Ex.: Moto Peças & Oficina Express',
    intervalSuggestions: [
      MaintenanceIntervalSuggestion(
        title: 'Lubrificação da corrente',
        category: 'Relação (corrente, pinhão e coroa)',
        intervalKm: 500,
        notes: 'A cada 500 km ou após rodar na chuva.',
      ),
      MaintenanceIntervalSuggestion(
        title: 'Ajuste e tensão da corrente',
        category: 'Relação (corrente, pinhão e coroa)',
        intervalKm: 1000,
        intervalMonths: 1,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Troca de óleo do motor (4T)',
        category: 'Óleo 4T',
        intervalKm: 3000,
        intervalMonths: 6,
        notes: 'Varia de 1.000 a 5.000 km conforme a cilindrada e o fabricante.',
      ),
      MaintenanceIntervalSuggestion(
        title: 'Filtro de óleo',
        category: 'Filtros',
        intervalKm: 6000,
        intervalMonths: 12,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Filtro de ar',
        category: 'Filtros',
        intervalKm: 10000,
        intervalMonths: 12,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Pastilhas / Lonas de freio',
        category: 'Freios',
        intervalKm: 5000,
        intervalMonths: 6,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Kit relação completo',
        category: 'Relação (corrente, pinhão e coroa)',
        intervalKm: 15000,
        intervalMonths: 24,
      ),
      MaintenanceIntervalSuggestion(
        title: 'Revisão periódica',
        category: 'Revisão',
        intervalKm: 5000,
        intervalMonths: 6,
      ),
    ],
  );

  static VehicleTypeConfig of(VehicleType type) => switch (type) {
    VehicleType.car => carConfig,
    VehicleType.motorcycle => motorcycleConfig,
  };

  static VehicleTypeConfig byString(String? typeStr) =>
      of(VehicleType.fromString(typeStr));
}
