import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/user_profile.dart';

/// Mapeamento entre FirebaseAuth User → UserProfile (com dados do Firestore).
extension FirebaseUserMapper on fb.User {
  UserProfile toProfile({String? name, String? plan}) => UserProfile(
    id: uid,
    name: name ?? displayName ?? (email?.split('@').first ?? 'Usuário'),
    email: email ?? '',
    plan: plan ?? 'free',
    createdAt: null, // preenchido via Firestore quando necessário
  );
}

/// Carrega o perfil completo a partir do documento /users/{uid}.
Future<UserProfile> fetchUserProfile({
  required fb.User user,
  required FirebaseFirestore firestore,
}) async {
  final doc = await firestore.collection('users').doc(user.uid).get();
  if (!doc.exists) return user.toProfile();
  final data = doc.data()!;
  return UserProfile(
    id: user.uid,
    name:
        (data['name'] as String?) ??
        user.displayName ??
        (user.email?.split('@').first ?? 'Usuário'),
    email: user.email ?? (data['email'] as String?) ?? '',
    plan: (data['plan'] as String?) ?? 'free',
    createdAt: (data['created_at'] as Timestamp?)?.toDate(),
  );
}
