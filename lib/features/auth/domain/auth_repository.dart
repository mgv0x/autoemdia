import '../domain/user_profile.dart';

/// Contrato da fonte de dados de autenticação.
abstract interface class AuthRepository {
  /// Usuário atual autenticação (ou null).
  UserProfile? get currentUser;

  Stream<UserProfile?> authStateChanges();

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<UserProfile> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<void> updateProfileName(String name);
}
