import 'package:auto_em_dia/features/vehicle/data/vehicle_model.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_type.dart';
import 'package:auto_em_dia/features/vehicle/domain/vehicle_type_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 6 — Moto: Adaptações de Duas Rodas e Vocabulário', () {
    test('VehicleType enum mapeia corretamente strings legadas e novas', () {
      expect(VehicleType.fromString('moto'), VehicleType.motorcycle);
      expect(VehicleType.fromString('motorcycle'), VehicleType.motorcycle);
      expect(VehicleType.fromString('car'), VehicleType.car);
      expect(VehicleType.fromString('carro'), VehicleType.car);
      expect(VehicleType.fromString(null), VehicleType.car);
      expect(VehicleType.fromString('desconhecido'), VehicleType.car);
    });

    test('VehicleTypeConfig diferencia terminologia e visibilidade de campos', () {
      final car = VehicleTypeConfig.of(VehicleType.car);
      final moto = VehicleTypeConfig.of(VehicleType.motorcycle);

      // Termos
      expect(car.vehicleTerm, 'carro');
      expect(moto.vehicleTerm, 'moto');
      expect(car.label, 'Carro');
      expect(moto.label, 'Moto');

      // Campos específicos
      expect(car.showDisplacement, isFalse);
      expect(moto.showDisplacement, isTrue);
      expect(moto.displacementHint, contains('160cc'));

      // Hints de serviço
      expect(car.serviceDescriptionHint, contains('óleo e filtro'));
      expect(moto.serviceDescriptionHint, contains('corrente'));
      expect(moto.serviceDescriptionHint, contains('4T'));

      // Hints de peças e oficinas
      expect(car.partHint, contains('Filtro Mann'));
      expect(moto.partHint, contains('Óleo Motul 5100 4T'));
      expect(moto.partHint, contains('Kit Relação'));
      expect(moto.workshopHint, contains('Moto Peças'));
    });

    test('Categorias de manutenção de moto são específicas e excluem itens de carro', () {
      final moto = VehicleTypeConfig.of(VehicleType.motorcycle);
      final car = VehicleTypeConfig.of(VehicleType.car);

      // Moto deve ter categorias de 2 rodas
      expect(moto.maintenanceCategories, contains('Óleo 4T'));
      expect(moto.maintenanceCategories, contains('Relação (corrente, pinhão e coroa)'));
      expect(moto.maintenanceCategories, contains('Filtros'));

      // Moto NÃO deve ter itens automotivos exclusivos de 4 rodas
      expect(moto.maintenanceCategories, isNot(contains('Ar-condicionado')));
      expect(moto.maintenanceCategories, isNot(contains('Direção')));

      // Carro possui seus itens específicos
      expect(car.maintenanceCategories, contains('Ar-condicionado'));
      expect(car.maintenanceCategories, contains('Direção'));
      expect(car.maintenanceCategories, isNot(contains('Relação (corrente, pinhão e coroa)')));
    });

    test('Sugestões de intervalos preventivos de moto cobrem ciclo rápido de 2 rodas', () {
      final moto = VehicleTypeConfig.of(VehicleType.motorcycle);
      final suggestions = moto.intervalSuggestions;

      expect(suggestions, isNotEmpty);

      // Lubrificação da corrente (ciclo curto: 500 km)
      final chainLube = suggestions.firstWhere(
        (s) => s.title.toLowerCase().contains('lubrificação da corrente'),
      );
      expect(chainLube.intervalKm, 500);
      expect(chainLube.category, contains('Relação'));
      expect(chainLube.summary, '500 km');

      // Ajuste de tensão da corrente (1000 km)
      final chainTension = suggestions.firstWhere(
        (s) => s.title.toLowerCase().contains('ajuste e tensão'),
      );
      expect(chainTension.intervalKm, 1000);
      expect(chainTension.intervalMonths, 1);
      expect(chainTension.summary, '1000 km ou 1 meses');

      // Troca de óleo 4T (3000 km / 6 meses)
      final oil4t = suggestions.firstWhere(
        (s) => s.title.toLowerCase().contains('óleo do motor (4t)'),
      );
      expect(oil4t.intervalKm, 3000);
      expect(oil4t.intervalMonths, 6);
      expect(oil4t.summary, '3000 km ou 6 meses');

      // Kit relação completo (15000 km)
      final kitRelacao = suggestions.firstWhere(
        (s) => s.title.toLowerCase().contains('kit relação completo'),
      );
      expect(kitRelacao.intervalKm, 15000);
      expect(kitRelacao.intervalMonths, 24);
    });

    test('Sugestões de intervalos de carro respeitam especificidades de 4 rodas', () {
      final car = VehicleTypeConfig.of(VehicleType.car);
      final suggestions = car.intervalSuggestions;

      // Alinhamento e balanceamento
      expect(
        suggestions.any((s) => s.title.toLowerCase().contains('alinhamento')),
        isTrue,
      );

      // Filtro do ar-condicionado
      expect(
        suggestions.any((s) => s.title.toLowerCase().contains('ar-condicionado')),
        isTrue,
      );
    });

    test('Model de Moto preserva cilindrada e dados no ciclo JSON', () {
      final moto = VehicleModel(
        id: 'moto-titan',
        userId: 'u-1',
        type: VehicleType.motorcycle,
        brand: 'Honda',
        model: 'CG 160 Titan',
        year: 2024,
        fuel: 'Flex',
        displacement: 162,
        currentMileage: 4200,
      );

      expect(moto.isMotorcycle, isTrue);
      expect(moto.isCar, isFalse);
      expect(moto.displacement, 162);
      expect(moto.displayName, 'Honda CG 160 Titan 2024');

      final json = VehicleModel.toJson(moto, userId: 'u-1');
      expect(json['type'], 'motorcycle');
      expect(json['displacement'], 162);

      final restored = VehicleModel.fromJson(json, id: 'moto-titan');
      expect(restored.isMotorcycle, isTrue);
      expect(restored.displacement, 162);
    });
  });
}
