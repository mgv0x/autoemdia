import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/env.dart';

/// Wrapper do AdMob. Usa IDs de teste durante desenvolvimento
/// (definidos em Env). Premium remove anúncios na UI (ver widgets).
class AdMobService {
  AdMobService._();

  static bool _initialized = false;

  /// Apenas inicializa no Android e quando não estiver em testes.
  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // Falha na inicialização de anúncios não deve derrubar o app.
    }
  }

  static bool get isInitialized => _initialized;

  static String get bannerAdUnitId => Env.admobBannerIdAndroid;
  static String get interstitialAdUnitId => Env.admobInterstitialIdAndroid;
}
