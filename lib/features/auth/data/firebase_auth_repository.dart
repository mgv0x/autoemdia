import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_mapper.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';
import 'firebase_user_mapper.dart';

/// Implementação do [AuthRepository] com Firebase Auth + Firestore.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  UserProfile? get currentUser => _auth.currentUser?.toProfile();

  @override
  Stream<UserProfile?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u?.toProfile());

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AppFailure('Não foi possível entrar. Tente novamente.');
      }
      // Garante que o documento do usuário existe em /users.
      await _ensureUserDoc(user);
      return user.toProfile();
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AppFailure(
          'Não foi possível criar a conta. Tente novamente.',
        );
      }
      // Define o displayName no Auth e cria o documento no Firestore.
      await user.updateDisplayName(name.trim());
      await _ensureUserDoc(user, name: name.trim());
      return user.toProfile(name: name.trim());
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final provider = fb.GoogleAuthProvider();
      final cred = await _auth.signInWithProvider(provider);
      final user = cred.user;
      if (user == null) {
        throw const AppFailure('Não foi possível entrar com o Google.');
      }
      await _ensureUserDoc(user);
      return user.toProfile();
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw handleError(e, 'Não foi possível enviar o e-mail de recuperação.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw handleError(e);
    }
  }

  @override
  Future<void> updateProfileName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
      }, SetOptions(merge: true));
    } catch (e) {
      throw handleError(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Remove os dados do usuário no Firestore (via função auxiliar do app).
    final uid = user.uid;
    try {
      await _deleteUserData(uid);
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AppFailure(
          'Por segurança, entre novamente na conta para excluí-la.',
        );
      }
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw handleError(e, 'Não foi possível excluir a conta agora.');
    }
  }

  /// Remove em lote os dados do usuário (veículos + coleções filhas + perfil).
  Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();

    // users
    batch.delete(_firestore.collection('users').doc(uid));

    // vehicles + coleções filhas (2 queries: vehicles by user, depois filhas)
    final vehicles = await _firestore
        .collection('vehicles')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final v in vehicles.docs) {
      batch.delete(v.reference);

      final maint = await _firestore
          .collection('maintenance_records')
          .where('vehicle_id', isEqualTo: v.id)
          .get();
      final rem = await _firestore
          .collection('reminders')
          .where('vehicle_id', isEqualTo: v.id)
          .get();
      final exp = await _firestore
          .collection('expenses')
          .where('vehicle_id', isEqualTo: v.id)
          .get();

      for (final d in maint.docs) {
        batch.delete(d.reference);
      }
      for (final d in rem.docs) {
        batch.delete(d.reference);
      }
      for (final d in exp.docs) {
        batch.delete(d.reference);
      }
    }

    // subscriptions
    final subs = await _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final d in subs.docs) {
      batch.delete(d.reference);
    }

    await batch.commit();
  }

  /// Garante que o documento /users/{uid} exista com os dados básicos.
  Future<void> _ensureUserDoc(fb.User user, {String? name}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final resolvedName =
        name ?? user.displayName ?? (user.email?.split('@').first ?? 'Usuário');

    if (!doc.exists) {
      await docRef.set({
        'name': resolvedName,
        'email': user.email ?? '',
        'plan': 'free',
        'created_at': FieldValue.serverTimestamp(),
      });
    } else if (name != null) {
      await docRef.set({'name': resolvedName}, SetOptions(merge: true));
    }
  }

  /// Mapeia FirebaseAuthException → AppFailure (mensagem amigável pt-BR).
  AppFailure _mapFirebaseAuthError(Object e) {
    if (e is fb.FirebaseAuthException) {
      return AppFailure(switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'E-mail ou senha incorretos. Verifique e tente novamente.',
        'email-already-in-use' =>
          'Este e-mail já está cadastrado. Tente fazer login.',
        'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
        'invalid-email' => 'Informe um e-mail válido.',
        'user-disabled' => 'Esta conta foi desativada.',
        'too-many-requests' => 'Muitas tentativas. Aguarde alguns instantes.',
        'operation-not-allowed' => 'Login com Google indisponível no momento.',
        'account-exists-with-different-credential' =>
          'Este e-mail já está cadastrado com outro provedor.',
        'requires-recent-login' =>
          'Por segurança, entre novamente para continuar.',
        _ => 'Não foi possível autenticar. Verifique os dados.',
      }, e);
    }
    return handleError(e);
  }
}
