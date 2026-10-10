import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../../core/constants/env.dart';
import '../../core/services/ad_manager.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/unity_ads_service.dart';
import '../../features/subscription/presentation/controllers/subscription_controller.dart';

/// Banner de anúncio responsivo exibido apenas para usuários do plano gratuito.
///
/// Características:
/// - Suporta Unity Ads (primária) e mantém AdMob preservado para testes/fallback.
/// - Altura reservada fixa de 50px (padrão standard banner), eliminando saltos bruscos no layout (CLS).
/// - Respeita o ciclo de vida da tela e não sobrepõe botões, formulários ou navegação.
/// - Não renderiza absolutamente nada (0px) para usuários do plano Premium.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  // Estado AdMob (Preservado)
  BannerAd? _admobBanner;
  bool _admobLoaded = false;

  // Estado Unity Ads
  bool _unityBannerLoaded = false;
  bool _unityFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndLoad();
    });
  }

  Future<void> _initAndLoad() async {
    final isPremium = ref.read(isPremiumProvider).value ?? false;
    if (isPremium) return;

    if (AdManager.activeNetwork == AdNetwork.unityAds) {
      if (!UnityAdsService.isInitialized) {
        await UnityAdsService.initialize();
      }
      if (mounted) setState(() {});
    } else {
      if (!AdMobService.isInitialized) {
        await AdMobService.initialize();
      }
      if (mounted) _loadAdmobBanner();
    }
  }

  void _loadAdmobBanner() {
    if (_admobBanner != null || !AdMobService.isInitialized) return;
    final isPremium = ref.read(isPremiumProvider).value ?? false;
    if (isPremium) return;

    _admobBanner = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('[AdMob] Banner carregado com sucesso!');
          if (mounted) setState(() => _admobLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[AdMob] Falha ao carregar banner: ${error.message} (código: ${error.code})',
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _admobBanner = null;
              _admobLoaded = false;
            });
            Future.delayed(const Duration(seconds: 15), () {
              if (mounted && _admobBanner == null) _loadAdmobBanner();
            });
          }
        },
      ),
    )..load();
  }

  void _disposeBanners() {
    _admobBanner?.dispose();
    _admobBanner = null;
    _admobLoaded = false;
    _unityBannerLoaded = false;
  }

  @override
  void dispose() {
    _disposeBanners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isPremiumProvider, (previous, next) {
      final isPremium = next.value ?? false;
      if (isPremium) {
        if (mounted) {
          setState(() {
            _disposeBanners();
          });
        }
      } else {
        _initAndLoad();
      }
    });

    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (isPremium) {
      return const SizedBox.shrink();
    }

    // 1. Rede Unity Ads ativa
    if (AdManager.activeNetwork == AdNetwork.unityAds) {
      return _buildUnityBannerSection();
    }

    // 2. Rede AdMob ativa (Preservada)
    return _buildAdmobBannerSection();
  }

  Widget _buildUnityBannerSection() {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile || _unityFailed) {
      return _buildPlaceholderSlot();
    }

    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_unityBannerLoaded) _buildPlaceholderSlot(),
            UnityBannerAd(
              placementId: Env.unityBannerPlacementId,
              size: BannerSize.standard,
              onLoad: (placementId) {
                debugPrint('[UnityAds] Banner carregado: $placementId');
                if (mounted) {
                  setState(() {
                    _unityBannerLoaded = true;
                    _unityFailed = false;
                  });
                }
              },
              onClick: (placementId) {
                debugPrint('[UnityAds] Clique no banner: $placementId');
              },
              onShown: (placementId) {
                debugPrint('[UnityAds] Banner exibido: $placementId');
              },
              onFailed: (placementId, error, errorMessage) {
                debugPrint('[UnityAds] Falha no banner ($placementId): $error - $errorMessage');
                if (mounted) {
                  setState(() {
                    _unityBannerLoaded = false;
                    _unityFailed = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmobBannerSection() {
    if (_admobBanner != null && _admobLoaded) {
      return SafeArea(
        top: false,
        child: Container(
          alignment: Alignment.center,
          width: _admobBanner!.size.width.toDouble(),
          height: _admobBanner!.size.height.toDouble(),
          color: Colors.transparent,
          child: AdWidget(ad: _admobBanner!),
        ),
      );
    }
    return _buildPlaceholderSlot();
  }

  Widget _buildPlaceholderSlot() {
    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ANÚNCIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Publicidade • Seja Premium para remover',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
