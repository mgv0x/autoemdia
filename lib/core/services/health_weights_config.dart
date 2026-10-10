/// Pesos e configurações para o cálculo da Saúde do Veículo (0–100).
/// Mantidos em arquivo único e configuráveis.
abstract final class HealthWeightsConfig {
  /// Pesos base para redistribuição proporcional.
  static const weightReviews = 25.0;       // Revisões periódicas
  static const weightOilMaintenance = 20.0; // Óleo e motor
  static const weightBrakes = 20.0;         // Freios
  static const weightTires = 20.0;          // Pneus
  static const weightOthers = 15.0;         // Lembretes gerais / outros

  /// Mínimo de cuidados com vencimento para emitir pontuação numérica válida.
  static const minimumItemsForScore = 2;

  /// Dias sem atualizar quilometragem para emitir aviso de km desatualizada.
  static const mileageStaleDaysThreshold = 30;

  /// Antecedência padrão sugerida em km e dias.
  static const defaultLeadKm = 500;
  static const defaultLeadDays = 30;

  /// Faixas de texto de acordo com a pontuação (0–100).
  static String statusText(int score) {
    if (score >= 85) return 'em boas condições';
    if (score >= 60) return 'atenção em alguns itens';
    return 'precisa de cuidados';
  }
}
