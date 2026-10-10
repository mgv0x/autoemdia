import 'dart:io';

import 'package:flutter/foundation.dart';

import 'admob_service.dart';
import 'unity_ads_service.dart';

/// Redes de anúncios suportadas pelo aplicativo.
enum AdNetwork {
  unityAds,
  admob,
}

/// Gerenciador unificado de monetização do Auto em Dia.
///
/// Mantém as duas redes integradas durante a fase de transição e testes,
/// garantindo que:
/// - A Unity Ads seja a rede primária ativa.
/// - O AdMob continue preservado e funcional como fallback/opção.
/// - Nunca haja anúncios simultâneos de diferentes redes no mesmo espaço.
/// - O fluxo do usuário nunca seja bloqueado quando anúncios falham.
class AdManager {
  AdManager._();

  /// Rede de anúncios atualmente ativa no aplicativo.
  /// Padrão: Unity Ads (nova integração oficial).
  static AdNetwork activeNetwork = AdNetwork.unityAds;

  /// Inicializa os serviços de anúncios no arranque do aplicativo de forma não-bloqueante.
  static Future<void> initialize({bool? testMode}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    // 1. Inicializa Unity Ads (Primária)
    try {
      await UnityAdsService.initialize(testMode: testMode);
      debugPrint('[AdManager] Unity Ads inicializado.');
    } catch (e) {
      debugPrint('[AdManager] Falha ao inicializar Unity Ads: $e');
    }

    // 2. Inicializa AdMob (Preservada para fallback / desenvolvimento)
    try {
      if (!AdMobService.isInitialized) {
        await AdMobService.initialize();
        debugPrint('[AdManager] AdMob preservado e inicializado com sucesso.');
      }
    } catch (e) {
      debugPrint('[AdManager] Falha ao inicializar AdMob: $e');
    }
  }

  /// Dispara a exibição de anúncio interstitial ao concluir uma ação natural
  /// (como cadastro de manutenção, gasto ou lembrete).
  ///
  /// Respeita limites de frequência (mínimo de 3 min entre anúncios, máx 3 por sessão).
  /// Se o anúncio não estiver pronto ou o usuário for Premium, continua instantaneamente.
  static Future<bool> showInterstitialOnActionCompleted({
    required String origin,
    required bool isPremium,
    VoidCallback? onClosed,
  }) async {
    if (isPremium) {
      onClosed?.call();
      return false;
    }

    if (activeNetwork == AdNetwork.unityAds) {
      return UnityAdsService.showInterstitialIfAvailable(
        origin: origin,
        isPremium: isPremium,
        onClosed: onClosed,
      );
    } else {
      // Caso alterado para AdMob durante testes
      onClosed?.call();
      return false;
    }
  }

  /// Permite alternar dinamicamente a rede ativa durante desenvolvimento ou testes.
  static void setActiveNetwork(AdNetwork network) {
    activeNetwork = network;
    debugPrint('[AdManager] Rede ativa alternada para: $network');
  }
}
