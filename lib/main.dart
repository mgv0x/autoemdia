import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/ad_manager.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/firebase_status.dart';
import 'core/services/notification_service.dart';
import 'shared/providers/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/providers/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase (Auth, Firestore, Crashlytics, Analytics)
  try {
    await FirebaseBootstrap.initialize();
  } catch (e, stack) {
    FirebaseStatus.initialized = false;
    debugPrint('Erro ao inicializar Firebase: $e\n$stack');
  }

  // 2. Notificações locais (seguro, não bloqueia inicialização da UI)
  try {
    await NotificationService.instance.init();
  } catch (e, stack) {
    debugPrint('Erro ao inicializar NotificationService: $e\n$stack');
  }

  // 3. Monetização (Unity Ads primária + AdMob preservada)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await AdManager.initialize();
    } catch (e) {
      debugPrint('Erro ao inicializar serviços de anúncios: $e');
    }
  }

  // 4. Configuração de erros globais (Crashlytics)
  if (FirebaseStatus.initialized) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
      }
    };
  }

  // 4.1. SharedPreferences (síncrono após o start)
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // 5. Evento inicial de analytics
  try {
    unawaited(container.read(analyticsServiceProvider).appOpened());
  } catch (_) {}

  // 6. Lembrete periódico de registrar quilometragem (usuários logados).
  // Agendado no background para não travar a inicialização.
  unawaited(_scheduleMileageReminderIfLoggedIn(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoEmDiaApp(),
    ),
  );
}

/// Agenda o lembrete mensal de km apenas quando há usuário autenticado.
Future<void> _scheduleMileageReminderIfLoggedIn(
  ProviderContainer container,
) async {
  try {
    if (!FirebaseStatus.initialized) return;
    // Aguarda um instante para o FirebaseAuth restaurar a sessão.
    final user = firebaseAuth.currentUser ?? await _waitForUser();
    if (user != null) {
      await NotificationService.instance.scheduleMileageReminder();
    }
  } catch (_) {
    // Nunca deve quebrar o start do app.
  }
}

/// Espera até 3s pelo primeiro evento de authStateChanges (sessão restaurada).
Future<dynamic> _waitForUser() async {
  try {
    final first = await firebaseAuth
        .authStateChanges()
        .where((u) => u != null)
        .first
        .timeout(const Duration(seconds: 3));
    return first;
  } catch (_) {
    return null;
  }
}
