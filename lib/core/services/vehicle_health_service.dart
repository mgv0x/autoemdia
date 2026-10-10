import '../../features/reminders/domain/reminder_entity.dart';
import 'health_weights_config.dart';

/// Explicação detalhada da pontuação de saúde.
class HealthExplanation {
  const HealthExplanation({
    required this.positiveItems,
    required this.warningItems,
    required this.criticalItems,
    required this.summary,
  });

  final List<String> positiveItems;
  final List<String> warningItems;
  final List<String> criticalItems;
  final String summary;
}

/// Pontuação e estado de uma categoria de cuidado.
class CategoryHealth {
  const CategoryHealth({
    required this.category,
    required this.normalizedScore, // 0.0 a 1.0
    required this.totalItems,
    required this.overdueItems,
    required this.upcomingItems,
    required this.upToDateItems,
  });

  final String category;
  final double normalizedScore;
  final int totalItems;
  final int overdueItems;
  final int upcomingItems;
  final int upToDateItems;
}

/// Resultado consolidado da Saúde do Veículo (0–100).
class VehicleHealthResult {
  const VehicleHealthResult({
    required this.hasEnoughData,
    this.score,
    required this.statusText,
    this.message,
    required this.isMileageStale,
    this.staleDays,
    required this.explanation,
    required this.categoryHealth,
  });

  /// Se há pelo menos 2 cuidados com data ou km para cálculo confiável.
  final bool hasEnoughData;

  /// Pontuação de 0 a 100 (ou null se sem dados suficientes).
  final int? score;

  /// Texto de status amigável (ex.: 'em boas condições', 'atenção em alguns itens').
  final String statusText;

  /// Mensagem explicativa ou de dados insuficientes.
  final String? message;

  /// Indica se a quilometragem não é atualizada há mais de 30 dias.
  final bool isMileageStale;

  /// Dias desde a última atualização de quilometragem.
  final int? staleDays;

  /// Explicação humana com motivos da pontuação.
  final HealthExplanation explanation;

  /// Detalhamento por categoria.
  final Map<String, CategoryHealth> categoryHealth;
}

/// Serviço puro de cálculo da Saúde do Veículo (0–100).
abstract final class VehicleHealthService {
  /// Mapeia categoria do lembrete para a categoria base de pesos.
  static String mapToHealthCategory(String? category) {
    final cat = (category ?? '').toLowerCase().trim();
    if (cat.contains('revisão') || cat.contains('revisao')) {
      return 'revisoes';
    }
    if (cat.contains('óleo') || cat.contains('oleo') || cat.contains('motor')) {
      return 'oleo_motor';
    }
    if (cat.contains('freio')) {
      return 'freios';
    }
    if (cat.contains('pneu') || cat.contains('alinhamento') || cat.contains('balanceamento')) {
      return 'pneus';
    }
    return 'outros';
  }

  /// Retorna o peso padrão para cada categoria base.
  static double baseWeightForCategory(String healthCategory) {
    return switch (healthCategory) {
      'revisoes' => HealthWeightsConfig.weightReviews,
      'oleo_motor' => HealthWeightsConfig.weightOilMaintenance,
      'freios' => HealthWeightsConfig.weightBrakes,
      'pneus' => HealthWeightsConfig.weightTires,
      _ => HealthWeightsConfig.weightOthers,
    };
  }

  /// Calcula a saúde geral do veículo a partir da lista de lembretes/cuidados.
  static VehicleHealthResult calculate({
    required List<ReminderEntity> reminders,
    required int currentMileage,
    DateTime? lastMileageUpdate,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();

    // 1. Verificação de km desatualizada
    bool isMileageStale = false;
    int? staleDays;
    if (lastMileageUpdate != null) {
      staleDays = today.difference(lastMileageUpdate).inDays;
      if (staleDays >= HealthWeightsConfig.mileageStaleDaysThreshold) {
        isMileageStale = true;
      }
    }

    // 2. Filtra lembretes ativos que tenham data ou quilometragem definida
    final activeItems = reminders
        .where((r) => !r.completed && (r.dueDate != null || r.dueMileage != null))
        .toList();

    // Regra: Mínimo de 2 cuidados com vencimento para emitir pontuação válida
    if (activeItems.length < HealthWeightsConfig.minimumItemsForScore) {
      return VehicleHealthResult(
        hasEnoughData: false,
        score: null,
        statusText: 'Sem dados suficientes',
        message: 'Cadastre pelo menos 2 cuidados com data ou quilometragem para calcular a saúde do veículo.',
        isMileageStale: isMileageStale,
        staleDays: staleDays,
        explanation: const HealthExplanation(
          positiveItems: [],
          warningItems: [],
          criticalItems: [],
          summary: 'Ainda não há dados suficientes para determinar a pontuação de saúde com precisão.',
        ),
        categoryHealth: const {},
      );
    }

    // 3. Agrupa itens por categoria de saúde
    final categoryItems = <String, List<ReminderEntity>>{};
    for (final item in activeItems) {
      final cat = mapToHealthCategory(item.category ?? item.title);
      categoryItems.putIfAbsent(cat, () => []).add(item);
    }

    // 4. Calcula pontuação por categoria e redistribui pesos proporcionalmente
    final positiveItems = <String>[];
    final warningItems = <String>[];
    final criticalItems = <String>[];
    final categoryHealthMap = <String, CategoryHealth>{};

    double totalWeightedScore = 0.0;
    double totalActiveWeights = 0.0;

    for (final entry in categoryItems.entries) {
      final catKey = entry.key;
      final items = entry.value;

      int upToDateCount = 0;
      int upcomingCount = 0;
      int overdueCount = 0;
      double catScoreSum = 0.0;

      for (final item in items) {
        final status = item.calculateStatus(currentMileage, today);
        switch (status) {
          case CareStatus.upToDate:
            upToDateCount++;
            catScoreSum += 1.0; // 100%
            positiveItems.add('${item.title} em dia');
            break;
          case CareStatus.upcoming:
            upcomingCount++;
            catScoreSum += 0.75; // 75%
            warningItems.add('${item.title} vence em breve');
            break;
          case CareStatus.overdue:
            overdueCount++;
            catScoreSum += 0.0; // 0%
            criticalItems.add('${item.title} vencido');
            break;
          case CareStatus.completed:
            break;
        }
      }

      final normalizedCatScore = items.isEmpty ? 1.0 : (catScoreSum / items.length);
      categoryHealthMap[catKey] = CategoryHealth(
        category: catKey,
        normalizedScore: normalizedCatScore,
        totalItems: items.length,
        overdueItems: overdueCount,
        upcomingItems: upcomingCount,
        upToDateItems: upToDateCount,
      );

      final weight = baseWeightForCategory(catKey);
      totalActiveWeights += weight;
      totalWeightedScore += normalizedCatScore * weight;
    }

    // Redistribuição proporcional para somar 100%
    final finalScoreDouble = totalActiveWeights > 0
        ? (totalWeightedScore / totalActiveWeights) * 100.0
        : 100.0;
    final finalScore = finalScoreDouble.clamp(0.0, 100.0).round();

    // 5. Geração da explicação humana
    final summaryBuffer = StringBuffer();
    if (finalScore >= 85) {
      summaryBuffer.write('Seu veículo está com a manutenção em excelentes condições. ');
    } else if (finalScore >= 60) {
      summaryBuffer.write('Seu veículo requer atenção para alguns itens próximos do vencimento. ');
    } else {
      summaryBuffer.write('Seu veículo precisa de cuidados urgentes com itens em atraso. ');
    }

    if (criticalItems.isNotEmpty) {
      summaryBuffer.write('Há ${criticalItems.length} item(ns) com prazo ou quilometragem vencida.');
    } else if (warningItems.isNotEmpty) {
      summaryBuffer.write('Há ${warningItems.length} item(ns) requerendo atenção em breve.');
    } else {
      summaryBuffer.write('Todos os cuidados monitorados estão em dia.');
    }

    return VehicleHealthResult(
      hasEnoughData: true,
      score: finalScore,
      statusText: HealthWeightsConfig.statusText(finalScore),
      message: null,
      isMileageStale: isMileageStale,
      staleDays: staleDays,
      explanation: HealthExplanation(
        positiveItems: positiveItems,
        warningItems: warningItems,
        criticalItems: criticalItems,
        summary: summaryBuffer.toString(),
      ),
      categoryHealth: categoryHealthMap,
    );
  }
}
