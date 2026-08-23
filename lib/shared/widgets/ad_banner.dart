import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/admob_service.dart';
import '../../features/subscription/presentation/controllers/subscription_controller.dart';

/// Banner de anúncio exibido apenas para usuários do plano gratuito.
/// Não é renderizado quando o usuário é Premium ou quando AdMob não
/// foi inicializado.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (!isPremium && AdMobService.isInitialized && _banner == null) {
      _banner = BannerAd(
        adUnitId: AdMobService.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _loaded = true),
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            setState(() {
              _banner = null;
              _loaded = false;
            });
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (isPremium || _banner == null || !_loaded) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _banner!.size.width.toDouble(),
        height: _banner!.size.height.toDouble(),
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
