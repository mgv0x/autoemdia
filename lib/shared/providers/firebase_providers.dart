import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/firebase_status.dart';

/// Providers centrais do Firebase (Auth + Firestore).
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => firebaseAuth);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => firestore);

/// Stream do estado de autenticação do Firebase.
final authUserStreamProvider = StreamProvider<fb.User?>((ref) {
  if (!FirebaseStatus.initialized) {
    return Stream.value(null);
  }
  try {
    return ref.watch(firebaseAuthProvider).authStateChanges();
  } catch (_) {
    return Stream.value(null);
  }
});

/// Usuário Firebase atual (ou null).
final currentAuthUserProvider = Provider<fb.User?>((ref) {
  if (!FirebaseStatus.initialized) return null;
  final asyncUser = ref.watch(authUserStreamProvider);
  if (asyncUser.hasValue) return asyncUser.value;
  try {
    return ref.watch(firebaseAuthProvider).currentUser;
  } catch (_) {
    return null;
  }
});
