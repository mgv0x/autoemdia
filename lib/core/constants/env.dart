// ─── Caminho central de configuração de ambiente ─────────────────────────
// Firebase: `google-services.json` + `firebase_options.dart` gerados pelo
// FlutterFire CLI. Rode `flutterfire configure` para gerar.
//
// Para variáveis sensíveis, use `--dart-define` OU `--dart-define-from-file=.env`.
// ──────────────────────────────────────────────────────────────────────────

class Env {
  Env._();

  // O Firebase é considerado "configurado" quando o google-services.json
  // foi adicionado (o que dispara a geração do firebase_options.dart).
  // Não precisa de variável de ambiente aqui.
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const googleSignInWebClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_WEB_CLIENT_ID',
  );

  static const admobAppIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const admobBannerIdAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const admobInterstitialIdAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  static const subscriptionMonthlyId = String.fromEnvironment(
    'SUBSCRIPTION_MONTHLY_ID',
    defaultValue: 'premium_mensal',
  );
  static const subscriptionYearlyId = String.fromEnvironment(
    'SUBSCRIPTION_YEARLY_ID',
    defaultValue: 'premium_anual',
  );

  static bool get isGoogleSignInConfigured =>
      googleSignInWebClientId.isNotEmpty;
}
