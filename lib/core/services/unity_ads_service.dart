import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../constants/env.dart';

/// Status de inicialização do SDK Unity Ads.
enum UnityAdsInitStatus {
  notInitialized,
  initializing,
  initialized,
  failed,
}

/// Gerenciador centralizado da Unity Ads para o Auto em Dia.
///
/// Implementa boas práticas de monetização responsável:
/// - Inicialização resiliente e idempotente (evita chamadas concorrentes duplicadas).
/// - Banner seguro sem salto de layout (layout shift) e com liberação de recursos.
/// - Interstitials exibidos apenas em transições naturais de conclusão de fluxo.
/// - Limites de frequência (cooldown mínimo de 3 min e teto de 3 por sessão).
/// - Formato Rewarded preparado e testado, porém desativado até definição de recompensa real.
/// - Isenção total para usuários do plano Premium.
class UnityAdsService {
  UnityAdsService._();

  static UnityAdsInitStatus _initStatus = UnityAdsInitStatus.notInitialized;
  static Completer<bool>? _initCompleter;

  // Estados dos Placements
  static bool _isInterstitialLoaded = false;
  static bool _isInterstitialLoading = false;
  static bool _isRewardedLoaded = false;
  static bool _isRewardedLoading = false;
  static bool _isAdShowing = false;

  // Políticas de Frequência & Sessão (Monetização Responsável)
  static DateTime? _lastInterstitialShownTime;
  static int _sessionInterstitialCount = 0;
  static const int maxInterstitialsPerSession = 3;
  static const Duration minIntervalBetweenInterstitials = Duration(minutes: 3);

  /// Formato Rewarded fica preparado na arquitetura, mas desativado por regra
  /// de produto até definição de uma recompensa real no aplicativo.
  static const bool isRewardedFeatureEnabled = false;

  // Getters públicos
  static UnityAdsInitStatus get initStatus => _initStatus;
  static bool get isInitialized => _initStatus == UnityAdsInitStatus.initialized;
  static bool get isInterstitialReady => _isInterstitialLoaded && !_isAdShowing;
  static bool get isRewardedReady => _isRewardedLoaded && !_isAdShowing;
  static bool get isAdShowing => _isAdShowing;
  static int get sessionInterstitialCount => _sessionInterstitialCount;

  /// Inicializa o SDK da Unity Ads com os identificadores oficiais do projeto.
  ///
  /// Retorna `true` se inicializado com sucesso, ou `false` se falhar.
  /// É idempotente: chamadas subsequentes reutilizam a inicialização existente.
  static Future<bool> initialize({bool? testMode}) async {
    // Unity Ads suporta apenas plataformas móveis suportadas (Android / iOS)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('[UnityAds] Plataforma não suportada para exibição móvel da Unity Ads.');
      return false;
    }

    if (_initStatus == UnityAdsInitStatus.initialized) {
      return true;
    }

    if (_initStatus == UnityAdsInitStatus.initializing && _initCompleter != null) {
      return _initCompleter!.future;
    }

    _initStatus = UnityAdsInitStatus.initializing;
    _initCompleter = Completer<bool>();

    final isTest = testMode ?? Env.isUnityTestMode;
    final gameId = Env.unityGameIdAndroid;

    debugPrint('[UnityAds] Inicializando Game ID: $gameId (testMode: $isTest)...');

    try {
      await UnityAds.init(
        gameId: gameId,
        testMode: isTest,
        onComplete: () {
          _initStatus = UnityAdsInitStatus.initialized;
          debugPrint('[UnityAds] SDK inicializado com sucesso.');
          if (!_initCompleter!.isCompleted) {
            _initCompleter!.complete(true);
          }
          // Pré-carrega o interstitial imediatamente para estar pronto em transições naturais
          loadInterstitial();
          if (isRewardedFeatureEnabled) {
            loadRewarded();
          }
        },
        onFailed: (error, errorMessage) {
          _initStatus = UnityAdsInitStatus.failed;
          debugPrint('[UnityAds] Falha na inicialização: $error - $errorMessage');
          if (!_initCompleter!.isCompleted) {
            _initCompleter!.complete(false);
          }
        },
      );
    } catch (e) {
      _initStatus = UnityAdsInitStatus.failed;
      debugPrint('[UnityAds] Erro inesperado ao disparar UnityAds.init: $e');
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete(false);
      }
    }

    return _initCompleter!.future;
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────

  /// Pré-carrega o anúncio interstitial em segundo plano.
  static Future<void> loadInterstitial() async {
    if (!isInitialized || _isInterstitialLoading || _isInterstitialLoaded) {
      return;
    }

    _isInterstitialLoading = true;
    final placementId = Env.unityInterstitialPlacementId;
    debugPrint('[UnityAds] Carregando interstitial placement: $placementId...');

    try {
      await UnityAds.load(
        placementId: placementId,
        onComplete: (pid) {
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
          debugPrint('[UnityAds] Interstitial carregado com sucesso: $pid');
        },
        onFailed: (pid, error, errorMessage) {
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
          debugPrint('[UnityAds] Falha ao carregar interstitial ($pid): $error - $errorMessage');
        },
      );
    } catch (e) {
      _isInterstitialLoaded = false;
      _isInterstitialLoading = false;
      debugPrint('[UnityAds] Erro ao carregar interstitial: $e');
    }
  }

  /// Exibe um anúncio interstitial se as políticas de monetização responsável forem atendidas:
  ///
  /// 1. Usuário NÃO é Premium.
  /// 2. SDK está inicializado e há anúncio pré-carregado.
  /// 3. O intervalo mínimo entre interstitials (3 min) já passou.
  /// 4. O limite máximo da sessão (3 exibições) não foi atingido.
  ///
  /// Retorna `true` se o anúncio começou a ser exibido, ou `false` se foi rejeitado/indisponível.
  /// O fluxo do aplicativo nunca é bloqueado se o anúncio não estiver pronto.
  static Future<bool> showInterstitialIfAvailable({
    required String origin,
    bool isPremium = false,
    VoidCallback? onClosed,
  }) async {
    if (isPremium) {
      debugPrint('[UnityAds] Usuário Premium: anúncio interstitial ignorado.');
      onClosed?.call();
      return false;
    }

    if (!isInitialized) {
      debugPrint('[UnityAds] Interstitial ignorado: SDK não inicializado.');
      onClosed?.call();
      return false;
    }

    if (_isAdShowing) {
      debugPrint('[UnityAds] Interstitial ignorado: outro anúncio já está em exibição.');
      onClosed?.call();
      return false;
    }

    // Regra de frequência máxima por sessão
    if (_sessionInterstitialCount >= maxInterstitialsPerSession) {
      debugPrint('[UnityAds] Interstitial ignorado: limite por sessão ($maxInterstitialsPerSession) atingido.');
      onClosed?.call();
      return false;
    }

    // Regra de intervalo mínimo entre anúncios
    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!);
      if (elapsed < minIntervalBetweenInterstitials) {
        final remainingSec = (minIntervalBetweenInterstitials - elapsed).inSeconds;
        debugPrint('[UnityAds] Interstitial em cooldown ($remainingSec s restantes). Origem: $origin');
        onClosed?.call();
        return false;
      }
    }

    if (!_isInterstitialLoaded) {
      debugPrint('[UnityAds] Interstitial não carregado no momento. Solicitando carga em background.');
      loadInterstitial();
      onClosed?.call();
      return false;
    }

    _isAdShowing = true;
    final placementId = Env.unityInterstitialPlacementId;
    debugPrint('[UnityAds] Exibindo interstitial ($placementId) a partir de: $origin');

    try {
      await UnityAds.showVideoAd(
        placementId: placementId,
        onStart: (pid) {
          debugPrint('[UnityAds] Interstitial iniciado: $pid');
        },
        onClick: (pid) {
          debugPrint('[UnityAds] Clique no interstitial: $pid');
        },
        onSkipped: (pid) {
          debugPrint('[UnityAds] Interstitial pulado pelo usuário: $pid');
          _onInterstitialFinished(onClosed);
        },
        onComplete: (pid) {
          debugPrint('[UnityAds] Interstitial completado: $pid');
          _onInterstitialFinished(onClosed);
        },
        onFailed: (pid, error, errorMessage) {
          debugPrint('[UnityAds] Falha ao exibir interstitial ($pid): $error - $errorMessage');
          _onInterstitialFinished(onClosed);
        },
      );
      return true;
    } catch (e) {
      debugPrint('[UnityAds] Erro ao chamar showVideoAd para interstitial: $e');
      _isAdShowing = false;
      _isInterstitialLoaded = false;
      onClosed?.call();
      loadInterstitial();
      return false;
    }
  }

  static void _onInterstitialFinished(VoidCallback? onClosed) {
    _isAdShowing = false;
    _isInterstitialLoaded = false;
    _lastInterstitialShownTime = DateTime.now();
    _sessionInterstitialCount++;

    onClosed?.call();

    // Recarrega o próximo anúncio em background com um delay amigável
    Future.delayed(const Duration(seconds: 10), () {
      loadInterstitial();
    });
  }

  // ─── Rewarded (Preparado e Desativado) ─────────────────────────────────────

  /// Pré-carrega o anúncio recompensado se o formato estiver ativado.
  static Future<void> loadRewarded() async {
    if (!isRewardedFeatureEnabled) {
      return;
    }

    if (!isInitialized || _isRewardedLoading || _isRewardedLoaded) {
      return;
    }

    _isRewardedLoading = true;
    final placementId = Env.unityRewardedPlacementId;

    try {
      await UnityAds.load(
        placementId: placementId,
        onComplete: (pid) {
          _isRewardedLoaded = true;
          _isRewardedLoading = false;
          debugPrint('[UnityAds] Rewarded carregado: $pid');
        },
        onFailed: (pid, error, errorMessage) {
          _isRewardedLoaded = false;
          _isRewardedLoading = false;
          debugPrint('[UnityAds] Falha ao carregar rewarded: $error - $errorMessage');
        },
      );
    } catch (e) {
      _isRewardedLoaded = false;
      _isRewardedLoading = false;
      debugPrint('[UnityAds] Erro ao carregar rewarded: $e');
    }
  }

  /// Exibe anúncio recompensado somente quando acionado pelo usuário e se o formato
  /// estiver formalmente habilitado. Concede recompensa apenas no callback oficial
  /// `onComplete` do SDK.
  static Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onDismissed,
    bool isPremium = false,
  }) async {
    if (!isRewardedFeatureEnabled) {
      debugPrint(
        '[UnityAds] Anúncio recompensado desativado: '
        'aguardando definição de valor/recompensa justa no produto.',
      );
      onDismissed?.call();
      return false;
    }

    if (isPremium || !isInitialized || !_isRewardedLoaded || _isAdShowing) {
      onDismissed?.call();
      return false;
    }

    _isAdShowing = true;
    final placementId = Env.unityRewardedPlacementId;

    try {
      await UnityAds.showVideoAd(
        placementId: placementId,
        onStart: (pid) => debugPrint('[UnityAds] Rewarded iniciado: $pid'),
        onClick: (pid) => debugPrint('[UnityAds] Clique no Rewarded: $pid'),
        onSkipped: (pid) {
          debugPrint('[UnityAds] Rewarded pulado: sem concessão de recompensa.');
          _isAdShowing = false;
          _isRewardedLoaded = false;
          onDismissed?.call();
          loadRewarded();
        },
        onComplete: (pid) {
          debugPrint('[UnityAds] Rewarded completado com sucesso: liberando recompensa.');
          _isAdShowing = false;
          _isRewardedLoaded = false;
          onRewardEarned();
          onDismissed?.call();
          loadRewarded();
        },
        onFailed: (pid, error, errorMessage) {
          debugPrint('[UnityAds] Falha ao exibir Rewarded: $error - $errorMessage');
          _isAdShowing = false;
          _isRewardedLoaded = false;
          onDismissed?.call();
          loadRewarded();
        },
      );
      return true;
    } catch (e) {
      debugPrint('[UnityAds] Erro ao exibir rewarded: $e');
      _isAdShowing = false;
      _isRewardedLoaded = false;
      onDismissed?.call();
      return false;
    }
  }

  // ─── Privacidade & Consentimento (GDPR / CCPA / PIPL) ─────────────────────

  /// Configura as flags de consentimento de privacidade conforme exigido
  /// pela Unity Ads e Google Play (GDPR, CCPA e Age Gate).
  static Future<void> setPrivacyConsent({
    bool? gdprConsent,
    bool? ccpaConsent,
    bool? ageGateConsent,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      if (gdprConsent != null) {
        await UnityAds.setPrivacyConsent(PrivacyConsentType.gdpr, gdprConsent);
      }
      if (ccpaConsent != null) {
        await UnityAds.setPrivacyConsent(PrivacyConsentType.ccpa, ccpaConsent);
      }
      if (ageGateConsent != null) {
        await UnityAds.setPrivacyConsent(PrivacyConsentType.ageGate, ageGateConsent);
      }
      debugPrint('[UnityAds] Flags de privacidade atualizadas com sucesso.');
    } catch (e) {
      debugPrint('[UnityAds] Erro ao definir flags de privacidade: $e');
    }
  }

  // ─── Utilitários para Testes Unitários ─────────────────────────────────────

  @visibleForTesting
  static void resetStateForTesting() {
    _initStatus = UnityAdsInitStatus.notInitialized;
    _initCompleter = null;
    _isInterstitialLoaded = false;
    _isInterstitialLoading = false;
    _isRewardedLoaded = false;
    _isRewardedLoading = false;
    _isAdShowing = false;
    _lastInterstitialShownTime = null;
    _sessionInterstitialCount = 0;
  }
}
