import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show FlutterError, debugPrint;

import '../../firebase_options.dart'; // gerado por `flutterfire configure`
import 'firebase_status.dart';

/// Inicializador do Firebase. Deve ser chamado no start do app.
abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      FirebaseStatus.initialized = true;

      // Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey('app', 'auto_em_dia'),
      );

      // Firestore: tolerância a rede instável — SDK mantém cache local.
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore settings já configurado ou ignorado: $e');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar FirebaseBootstrap: $e');
      // Não rethrow para permitir fallback suave do app
    }
  }
}

/// Acesso seguro aos serviços Firebase via getters.
fb.FirebaseAuth get firebaseAuth => fb.FirebaseAuth.instance;
FirebaseFirestore get firestore => FirebaseFirestore.instance;
