import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../shared/providers/analytics_provider.dart';
import '../../data/subscription_repository.dart';

class SubscriptionController extends Notifier<AsyncValue<ProductDetails?>> {
  @override
  AsyncValue<ProductDetails?> build() => const AsyncData(null);

  Future<bool> buy(ProductDetails product) async {
    state = const AsyncLoading();
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      await repo.buy(product);
      ref.read(analyticsServiceProvider).subscriptionStarted();
      return product;
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> restore() async {
    state = const AsyncLoading();
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      await repo.initialize();
      return null;
    });
    state = result;
    ref.invalidate(subscriptionProvider);
    return !result.hasError;
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, AsyncValue<ProductDetails?>>(
      SubscriptionController.new,
    );

/// Produtos da loja (Google Play Billing).
final subscriptionProductsProvider = FutureProvider<List<ProductDetails>>((
  ref,
) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.loadProducts();
});

/// Alias para facilitar leitura na UI (vem de subscription_repository).
final isPremiumProvider = subscriptionProvider;
