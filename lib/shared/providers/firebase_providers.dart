import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_bootstrap.dart';

/// Providers centrais do Firebase (Auth + Firestore).
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => firebaseAuth);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => firestore);

/// Stream do estado de autenticação do Firebase.
final authUserStreamProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Usuário Firebase atual (ou null).
final currentAuthUserProvider = Provider<fb.User?>((ref) {
  final asyncUser = ref.watch(authUserStreamProvider);
  if (asyncUser.hasValue) return asyncUser.value;
  return ref.watch(firebaseAuthProvider).currentUser;
});
