import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/admob_service.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/firebase_status.dart';
import 'core/services/notification_service.dart';
import 'shared/providers/analytics_provider.dart';

Future<void> main() async {
  final container = ProviderContainer();
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase (obrigatório para auth e banco nesta versão).
      // Se o app ainda não tiver google-services.json / firebase_options.dart,
      // o Firebase.initializeApp lança e caimos no fallback.
      try {
        await FirebaseBootstrap.initialize();
        FirebaseStatus.initialized = true;
      } catch (_) {
        FirebaseStatus.initialized = false;
      }

      // Notificações locais
      await NotificationService.instance.init();

      // AdMob (apenas Android)
      if (!kIsWeb && Platform.isAndroid) {
        await AdMobService.initialize();
      }

      // Evento inicial de analytics (não quebra se o Firebase não estiver pronto)
      unawaited(container.read(analyticsServiceProvider).appOpened());
    },
    (error, stack) {
      if (FirebaseStatus.initialized) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else if (kDebugMode) {
        debugPrint('Erro não tratado: $error\n$stack');
      }
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoEmDiaApp(),
    ),
  );
}
