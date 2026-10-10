// ─── Caminho central de configuração de ambiente ─────────────────────────
// Firebase: `google-services.json` + `firebase_options.dart` gerados pelo
// FlutterFire CLI. Rode `flutterfire configure` para gerar.
//
// Para variáveis sensíveis, use `--dart-define` OU `--dart-define-from-file=.env`.
// ──────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';

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
    defaultValue: 'ca-app-pub-4682235144071285~6987686889',
  );
  static const admobBannerIdAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ID_ANDROID',
    defaultValue: 'ca-app-pub-4682235144071285/9926775646',
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

  // ─── Unity Ads (Configuração oficial) ────────────────────────────────────
  static const unityGameIdAndroid = String.fromEnvironment(
    'UNITY_GAME_ID_ANDROID',
    defaultValue: '800394548',
  );
  static const unityBannerPlacementId = String.fromEnvironment(
    'UNITY_BANNER_PLACEMENT_ID',
    defaultValue: 'BP_Banner_Android',
  );
  static const unityInterstitialPlacementId = String.fromEnvironment(
    'UNITY_INTERSTITIAL_PLACEMENT_ID',
    defaultValue: 'BP_Interstitial_Android',
  );
  static const unityRewardedPlacementId = String.fromEnvironment(
    'UNITY_REWARDED_PLACEMENT_ID',
    defaultValue: 'BP_Rewarded_Android',
  );
  static const unityOrganizationCoreId = '4674265524394';

  static const bool _unityTestModeOverride = bool.fromEnvironment(
    'UNITY_TEST_MODE',
    defaultValue: true,
  );
  static bool get isUnityTestMode =>
      kDebugMode || _unityTestModeOverride;

  static bool get isGoogleSignInConfigured =>
      googleSignInWebClientId.isNotEmpty;
}
