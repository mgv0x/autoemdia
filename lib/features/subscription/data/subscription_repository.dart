import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/constants/env.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../shared/providers/firebase_providers.dart';

/// Preços de referência usados apenas como fallback visual quando a loja
/// ainda não está configurada. Os valores reais e o produto ativo vêm
/// do Google Play Billing.
abstract final class SubscriptionConfig {
  static const productIds = <String>{
    Env.subscriptionMonthlyId,
    Env.subscriptionYearlyId,
  };
}

/// Camada de assinatura: integra Google Play Billing e persiste no Firestore.
class SubscriptionRepository {
  SubscriptionRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchasesSub;

  bool _billingAvailable = false;
  bool get billingAvailable => _billingAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => List.unmodifiable(_products);

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  String? get _uid => _auth.currentUser?.uid;

  /// Inicia escuta de compras e consulta a loja. Deve ser chamado uma vez.
  Future<void> initialize() async {
    try {
      _billingAvailable = await _iap.isAvailable();
    } catch (_) {
      _billingAvailable = false;
    }
    if (_billingAvailable) {
      _purchasesSub ??= _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (_) {},
      );
    }
    await refreshStatus();
  }

  /// Restaura compras efetuadas pelo usuário na Google Play Store.
  Future<void> restorePurchases() async {
    if (!_billingAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
    await refreshStatus();
  }

  /// Consulta os produtos disponíveis na loja.
  Future<List<ProductDetails>> loadProducts() async {
    if (!_billingAvailable) return [];
    try {
      final response = await _iap.queryProductDetails(
        SubscriptionConfig.productIds,
      );
      _products = response.productDetails;
      return _products;
    } catch (_) {
      return [];
    }
  }

  /// Inicia o fluxo de compra de assinatura (não-consumível de assinatura).
  Future<void> buy(ProductDetails product) async {
    if (!_billingAvailable) {
      throw const AppFailure(
        'Loja indisponível no momento. Tente novamente mais tarde.',
      );
    }
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _recordSubscription(p);
      }
    }
    await refreshStatus();
  }

  /// Persiste a assinatura no Firestore e marca o plano do usuário como premium.
  Future<void> _recordSubscription(PurchaseDetails p) async {
    final uid = _uid;
    if (uid == null) return;
    final isMonthly =
        p.productID.toLowerCase().contains('mensal') ||
        p.productID.toLowerCase().contains('monthly');
    final now = DateTime.now();
    final expires = isMonthly
        ? now.add(const Duration(days: 31))
        : now.add(const Duration(days: 366));

    try {
      await _db.collection('subscriptions').add({
        'user_id': uid,
        'product_id': p.productID,
        'status': 'active',
        'started_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(expires),
      });
      await _db.collection('users').doc(uid).set({
        'plan': 'premium',
      }, SetOptions(merge: true));
    } catch (_) {
      // Falha de persistência não impede a entrega.
    }
  }

  /// Alterna o plano entre free e premium para fins de teste no emulador / sandbox.
  Future<void> toggleDebugPlan() async {
    final uid = _uid;
    if (uid == null) return;
    final current = await refreshStatus();
    final newPlan = current ? 'free' : 'premium';
    try {
      await _db.collection('users').doc(uid).set({
        'plan': newPlan,
      }, SetOptions(merge: true));
      if (!current) {
        await _db.collection('subscriptions').add({
          'user_id': uid,
          'product_id': 'premium_sandbox',
          'status': 'active',
          'started_at': Timestamp.fromDate(DateTime.now()),
          'expires_at': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        });
      } else {
        final snap = await _db
            .collection('subscriptions')
            .where('user_id', isEqualTo: uid)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.update({'status': 'canceled'});
        }
      }
    } catch (_) {}
    await refreshStatus();
  }

  /// Atualiza o status Premium a partir do Firestore (sem exigir índice composto).
  Future<bool> refreshStatus() async {
    final uid = _uid;
    var active = false;
    if (uid != null) {
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        final plan = userDoc.data()?['plan'];
        if (plan == 'free') {
          active = false;
        } else if (plan == 'premium') {
          active = true;
        } else {
          final snap = await _db
              .collection('subscriptions')
              .where('user_id', isEqualTo: uid)
              .where('status', isEqualTo: 'active')
              .get();
          if (snap.docs.isNotEmpty) {
            final now = DateTime.now();
            for (final d in snap.docs) {
              final data = d.data();
              final expires = (data['expires_at'] as Timestamp?)?.toDate();
              if (expires == null || expires.isAfter(now)) {
                active = true;
                break;
              }
            }
          }
        }
      } catch (_) {
        // Falha de consulta: mantém o último status conhecido.
      }
    }
    _statusController.add(active);
    return active;
  }

  Future<bool> currentStatus() => refreshStatus();

  Future<void> dispose() async {
    await _purchasesSub?.cancel();
    await _statusController.close();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final repo = SubscriptionRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Provider booleano indicando se o usuário tem assinatura ativa.
final subscriptionProvider = StreamProvider<bool>((ref) async* {
  final repo = ref.watch(subscriptionRepositoryProvider);
  await repo.initialize();
  // Emite o estado inicial após consulta ao Firestore.
  yield await repo.currentStatus();
  // Escuta mudanças subsequentes (compras/restores).
  await for (final v in repo.statusStream) {
    yield v;
  }
});
