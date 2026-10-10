import '../../features/vehicle/domain/mileage_log_entity.dart';

/// Taxa projetada de uso diário do veículo.
class ProjectionRateResult {
  const ProjectionRateResult({
    required this.hasEnoughData,
    this.kmPerDay,
    required this.totalDaysAnalyzed,
    required this.totalKmLogged,
    this.message,
  });

  final bool hasEnoughData;
  final double? kmPerDay;
  final int totalDaysAnalyzed;
  final int totalKmLogged;
  final String? message;
}

/// Estimativa de data para um cuidado futuro por km.
class ProjectedCareDate {
  const ProjectedCareDate({
    required this.targetMileage,
    required this.kmRemaining,
    required this.estimatedDate,
    required this.daysRemaining,
  });

  final int targetMileage;
  final int kmRemaining;
  final DateTime estimatedDate;
  final int daysRemaining;
}

/// Serviço de projeção inteligente de uso e datas estimadas de cuidados.
abstract final class CareProjectionService {
  /// Janela máxima de análise para taxa de km recente (dias).
  static const analysisWindowDays = 90;

  /// Calcula a taxa média de km rodados por dia a partir dos logs recentes.
  static ProjectionRateResult calculateKmPerDay({
    required List<MileageLogEntity> logs,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final cutoff = today.subtract(const Duration(days: analysisWindowDays));

    // Filtra logs recentes dentro da janela de análise
    final recentLogs = logs.where((l) => l.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recentLogs.length < 2) {
      return const ProjectionRateResult(
        hasEnoughData: false,
        kmPerDay: null,
        totalDaysAnalyzed: 0,
        totalKmLogged: 0,
        message: 'Cadastre pelo menos 2 registros de quilometragem para projetar prazos.',
      );
    }

    final earliest = recentLogs.first;
    final latest = recentLogs.last;

    final daysDiff = latest.date.difference(earliest.date).inDays;
    final kmDiff = latest.mileage - earliest.mileage;

    if (daysDiff < 1 || kmDiff <= 0) {
      return const ProjectionRateResult(
        hasEnoughData: false,
        kmPerDay: null,
        totalDaysAnalyzed: 0,
        totalKmLogged: 0,
        message: 'Intervalo de datas ou quilometragem insuficiente para calcular a média diária.',
      );
    }

    final rate = kmDiff / daysDiff;
    return ProjectionRateResult(
      hasEnoughData: true,
      kmPerDay: rate,
      totalDaysAnalyzed: daysDiff,
      totalKmLogged: kmDiff,
    );
  }

  /// Estima a data de vencimento com base na quilometragem alvo e na taxa diária.
  static ProjectedCareDate? estimateDate({
    required int targetMileage,
    required int currentMileage,
    required double kmPerDay,
    DateTime? fromDate,
  }) {
    if (kmPerDay <= 0) return null;

    final baseDate = fromDate ?? DateTime.now();
    final kmRemaining = targetMileage - currentMileage;

    if (kmRemaining <= 0) {
      // Já atingiu a km alvo
      return ProjectedCareDate(
        targetMileage: targetMileage,
        kmRemaining: kmRemaining,
        estimatedDate: baseDate,
        daysRemaining: 0,
      );
    }

    final estimatedDays = (kmRemaining / kmPerDay).round();
    final projectedDate = baseDate.add(Duration(days: estimatedDays));

    return ProjectedCareDate(
      targetMileage: targetMileage,
      kmRemaining: kmRemaining,
      estimatedDate: projectedDate,
      daysRemaining: estimatedDays,
    );
  }
}
