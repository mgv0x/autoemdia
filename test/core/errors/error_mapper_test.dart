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

    test('Sem internet vira mensagem de conexão', () {
      final e = const SocketException('no route to host');
      expect(handleError(e).message, contains('conexão'));
    });

    test('Erro genérico usa fallback amigável', () {
      final e = Exception('algo estranho');
      expect(handleError(e).message, contains('erro inesperado'));
    });
  });
}
