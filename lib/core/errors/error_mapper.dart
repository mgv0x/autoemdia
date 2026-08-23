import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_failure.dart';

/// Traduz exceções técnicas em [AppFailure] com mensagens amigáveis em pt-BR.
/// Nunca exponha stack trace ou mensagens técnicas ao usuário.
AppFailure handleError(
  Object error, [
  String fallback = 'Ocorreu um erro inesperado. Tente novamente.',
]) {
  if (error is AppFailure) return error;

  if (error is fb.FirebaseAuthException) {
    return AppFailure(_mapFirebaseAuth(error));
  }
  if (error is FirebaseException) {
    return AppFailure(_mapFirebase(error));
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return const AppFailure(
      'Sem conexão com a internet. Verifique sua conexão e tente novamente.',
    );
  }
  return AppFailure(fallback, error);
}

String _mapFirebaseAuth(fb.FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou senha incorretos. Verifique e tente novamente.';
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado. Tente fazer login.';
    case 'weak-password':
      return 'A senha deve ter pelo menos 6 caracteres.';
    case 'invalid-email':
      return 'Informe um e-mail válido.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns instantes e tente novamente.';
    case 'operation-not-allowed':
      return 'Login com Google indisponível no momento.';
    case 'requires-recent-login':
      return 'Por segurança, entre novamente na sua conta.';
    default:
      return 'Não foi possível autenticar. Verifique os dados.';
  }
}

String _mapFirebase(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return 'Você não tem permissão para realizar esta operação.';
    case 'unavailable':
    case 'network-request-failed':
      return 'Sem conexão com a internet. Tente novamente.';
    case 'not-found':
      return 'O dado solicitado não foi encontrado.';
    case 'already-exists':
      return 'Este registro já existe.';
    case 'resource-exhausted':
      return 'Limite excedido. Tente novamente em alguns minutos.';
    case 'unauthenticated':
      return 'Sua sessão expirou. Faça login novamente.';
    default:
      return 'Erro ao acessar o banco de dados. Tente novamente.';
  }
}
