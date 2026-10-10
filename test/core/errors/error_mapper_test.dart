import 'dart:async';
import 'dart:io';

import 'package:auto_em_dia/core/errors/app_failure.dart';
import 'package:auto_em_dia/core/errors/error_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('handleError', () {
    test('AppFailure retorna a si mesmo', () {
      const failure = AppFailure('Mensagem amigável');
      expect(handleError(failure).message, 'Mensagem amigável');
    });

    test('FirebaseAuthException (credenciais inválidas)', () {
      final e = fb.FirebaseAuthException(code: 'invalid-credential');
      expect(handleError(e).message, contains('E-mail ou senha incorretos'));
    });

    test('FirebaseAuthException (e-mail já em uso)', () {
      final e = fb.FirebaseAuthException(code: 'email-already-in-use');
      expect(handleError(e).message, contains('já está cadastrado'));
    });

    test('FirebaseAuthException (senha fraca)', () {
      final e = fb.FirebaseAuthException(code: 'weak-password');
      expect(handleError(e).message, contains('pelo menos 6 caracteres'));
    });

    test('FirebaseException permission-denied (simula RLS)', () {
      final e = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions',
      );
      expect(handleError(e).message, contains('não tem permissão'));
    });

    test('FirebaseException unavailable ou network-request-failed (offline)', () {
      final unavail = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      expect(handleError(unavail).message, contains('conexão com a internet'));

      final netFail = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'network-request-failed',
      );
      expect(handleError(netFail).message, contains('conexão com a internet'));
    });

    test('TimeoutException e HttpException viram mensagem de conexão amigável', () {
      final timeout = TimeoutException('Tempo esgotado');
      expect(handleError(timeout).message, contains('Sem conexão com a internet'));

      final http = const HttpException('Falha HTTP');
      expect(handleError(http).message, contains('Sem conexão com a internet'));
    });

    test('Sem internet vira mensagem de conexão', () {
      final e = const SocketException('no route to host');
      expect(handleError(e).message, contains('conexão'));
    });

    test('Erro genérico usa fallback amigável ou personalizado', () {
      final e = Exception('algo estranho');
      expect(handleError(e).message, contains('erro inesperado'));
      expect(
        handleError(e, 'Mensagem customizada para falha de salvar').message,
        'Mensagem customizada para falha de salvar',
      );
    });
  });
}
