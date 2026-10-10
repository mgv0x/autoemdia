import 'package:auto_em_dia/core/constants/env.dart';
import 'package:auto_em_dia/core/services/ad_manager.dart';
import 'package:auto_em_dia/core/services/unity_ads_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unity Ads — Configurações e Identificadores Oficiais', () {
    test('IDs do painel estão devidamente configurados no Env', () {
      expect(Env.unityGameIdAndroid, equals('800394548'));
      expect(Env.unityBannerPlacementId, equals('BP_Banner_Android'));
      expect(Env.unityInterstitialPlacementId, equals('BP_Interstitial_Android'));
      expect(Env.unityRewardedPlacementId, equals('BP_Rewarded_Android'));
      expect(Env.unityOrganizationCoreId, equals('4674265524394'));
    });
  });

  group('UnityAdsService — Regras de Monetização Responsável', () {
    setUp(() {
      UnityAdsService.resetStateForTesting();
    });

    test('Usuário Premium nunca deve receber interstitial', () async {
      final shown = await UnityAdsService.showInterstitialIfAvailable(
        origin: 'test_origin',
        isPremium: true,
      );
      expect(shown, isFalse);
    });

    test('Interstitial não é exibido se SDK não estiver inicializado', () async {
      expect(UnityAdsService.isInitialized, isFalse);
      final shown = await UnityAdsService.showInterstitialIfAvailable(
        origin: 'test_origin',
        isPremium: false,
      );
      expect(shown, isFalse);
    });

    test('Limites de frequência respeitam intervalo de 3 min e 3 exibições/sessão', () {
      expect(UnityAdsService.maxInterstitialsPerSession, equals(3));
      expect(
        UnityAdsService.minIntervalBetweenInterstitials,
        equals(const Duration(minutes: 3)),
      );
    });

    test('Rewarded fica preparado na arquitetura mas desativado por padrão', () async {
      expect(UnityAdsService.isRewardedFeatureEnabled, isFalse);

      var rewardedCalled = false;
      var dismissedCalled = false;

      final shown = await UnityAdsService.showRewardedAd(
        onRewardEarned: () => rewardedCalled = true,
        onDismissed: () => dismissedCalled = true,
        isPremium: false,
      );

      expect(shown, isFalse);
      expect(rewardedCalled, isFalse);
      expect(dismissedCalled, isTrue);
    });
  });

  group('AdManager — Orquestração e Preservação de Redes', () {
    test('Rede ativa padrão é Unity Ads e permite alternar para AdMob', () {
      expect(AdManager.activeNetwork, equals(AdNetwork.unityAds));

      AdManager.setActiveNetwork(AdNetwork.admob);
      expect(AdManager.activeNetwork, equals(AdNetwork.admob));

      AdManager.setActiveNetwork(AdNetwork.unityAds);
      expect(AdManager.activeNetwork, equals(AdNetwork.unityAds));
    });

    test('AdManager rejeita exibição imediata para usuário Premium', () async {
      var closed = false;
      final shown = await AdManager.showInterstitialOnActionCompleted(
        origin: 'test_action',
        isPremium: true,
        onClosed: () => closed = true,
      );

      expect(shown, isFalse);
      expect(closed, isTrue);
    });
  });
}
