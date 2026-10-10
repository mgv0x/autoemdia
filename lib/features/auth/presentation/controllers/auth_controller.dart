import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../shared/providers/analytics_provider.dart';
import '../../../../../../shared/providers/firebase_providers.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_profile.dart';
import '../../data/firebase_auth_repository.dart';
import '../../data/firebase_user_mapper.dart';

import '../../../../core/services/firebase_status.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// Estado atual do usuário via stream de auth (com perfil do Firestore).
final authStreamProvider = StreamProvider<UserProfile?>((ref) {
  if (!FirebaseStatus.initialized) {
    return Stream.value(null);
  }
  try {
    final authRepo = ref.watch(authRepositoryProvider);
    final auth = ref.watch(firebaseAuthProvider);
    final firestore = ref.watch(firestoreProvider);
    return authRepo.authStateChanges().asyncMap((_) async {
      final user = auth.currentUser;
      if (user == null) return null;
      return fetchUserProfile(user: user, firestore: firestore);
    });
  } catch (_) {
    return Stream.value(null);
  }
});

/// Controller de formulários de autenticação.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) => _run(() async {
    final user = await _repo.signInWithEmail(email: email, password: password);
    ref.read(analyticsServiceProvider).loginCompleted();
    return user;
  });

  Future<bool> signUp(String name, String email, String password) =>
      _run(() async {
        final user = await _repo.signUp(
          name: name,
          email: email,
          password: password,
        );
        ref.read(analyticsServiceProvider).signupCompleted();
        return user;
      });

  Future<bool> signInWithGoogle() => _run(() async {
    final user = await _repo.signInWithGoogle();
    ref.read(analyticsServiceProvider).loginCompleted();
    return user;
  });

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<void> signOut() async {
    await _run(() => _repo.signOut());
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
    });
    return !state.hasError;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
