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
      debugPrint('[AdMob] SDK inicializado com sucesso.');
    } catch (e) {
      debugPrint('[AdMob] Falha ao inicializar SDK: $e');
    }
  }

  static bool get isInitialized => _initialized;

  static String get bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : (Env.admobBannerIdAndroid.isNotEmpty
          ? Env.admobBannerIdAndroid
          : 'ca-app-pub-3940256099942544/6300978111');

  static String get interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : (Env.admobInterstitialIdAndroid.isNotEmpty
          ? Env.admobInterstitialIdAndroid
          : 'ca-app-pub-3940256099942544/1033173712');
}
