import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show FlutterError;

import '../../firebase_options.dart'; // gerado por `flutterfire configure`

/// Inicializador do Firebase. Deve ser chamado uma única vez no start do app.
abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;

    // Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    unawaited(FirebaseCrashlytics.instance.setCustomKey('app', 'auto_em_dia'));

    // Firestore: tolerância a rede instável — SDK mantém cache local.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}

/// Acesso centralizado aos serviços Firebase.
final firebaseAuth = fb.FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
