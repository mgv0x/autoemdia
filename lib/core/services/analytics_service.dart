import 'package:firebase_analytics/firebase_analytics.dart';

/// Fachada para eventos de Analytics. Não enviar dados pessoais
/// (e-mail, nome, placa etc.) — apenas eventos agregados de produto.
abstract interface class AnalyticsService {
  Future<void> appOpened();
  Future<void> signupCompleted();
  Future<void> loginCompleted();
  Future<void> vehicleCreated();
  Future<void> maintenanceCreated();
  Future<void> reminderCreated();
  Future<void> reminderCompleted();
  Future<void> expenseCreated();
  Future<void> premiumScreenViewed();
  Future<void> subscriptionStarted();
  Future<void> subscriptionCancelled();
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> appOpened() => _log('app_opened');
  @override
  Future<void> signupCompleted() => _log('signup_completed');
  @override
  Future<void> loginCompleted() => _log('login_completed');
  @override
  Future<void> vehicleCreated() => _log('vehicle_created');
  @override
  Future<void> maintenanceCreated() => _log('maintenance_created');
  @override
  Future<void> reminderCreated() => _log('reminder_created');
  @override
  Future<void> reminderCompleted() => _log('reminder_completed');
  @override
  Future<void> expenseCreated() => _log('expense_created');
  @override
  Future<void> premiumScreenViewed() => _log('premium_screen_viewed');
  @override
  Future<void> subscriptionStarted() => _log('subscription_started');
  @override
  Future<void> subscriptionCancelled() => _log('subscription_cancelled');

  Future<void> _log(String name) async {
    try {
      await _analytics.logEvent(name: name);
    } catch (_) {
      // Analytics nunca deve quebrar o fluxo do app.
    }
  }
}

/// Implementação sem efeito usada quando o Firebase não está configurado.
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();
  @override
  Future<void> appOpened() async {}
  @override
  Future<void> signupCompleted() async {}
  @override
  Future<void> loginCompleted() async {}
  @override
  Future<void> vehicleCreated() async {}
  @override
  Future<void> maintenanceCreated() async {}
  @override
  Future<void> reminderCreated() async {}
  @override
  Future<void> reminderCompleted() async {}
  @override
  Future<void> expenseCreated() async {}
  @override
  Future<void> premiumScreenViewed() async {}
  @override
  Future<void> subscriptionStarted() async {}
  @override
  Future<void> subscriptionCancelled() async {}
}
