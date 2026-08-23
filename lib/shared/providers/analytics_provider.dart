import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/firebase_status.dart';

/// Provider do serviço de Analytics.
/// Usa o Firebase quando configurado; caso contrário, retorna no-op
/// (o app nunca quebra por falta de configuração de analytics).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (FirebaseStatus.initialized) {
    return FirebaseAnalyticsService(FirebaseAnalytics.instance);
  }
  return const NoOpAnalyticsService();
});
