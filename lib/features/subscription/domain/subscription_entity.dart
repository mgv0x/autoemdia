/// Entidade de domínio: assinatura.
class SubscriptionEntity {
  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String status; // 'active' | 'expired' | 'cancelled' | 'pending'
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isActive {
    if (status != 'active') return false;
    final exp = expiresAt;
    if (exp == null) return true;
    return exp.isAfter(DateTime.now());
  }
}
