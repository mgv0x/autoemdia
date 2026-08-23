import 'package:auto_em_dia/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mail válido', () {
      expect(Validators.email('usuario@exemplo.com'), isNull);
      expect(Validators.email('a+b@dominio.com.br'), isNull);
    });
    test('rejeita e-mail inválido', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('abc@'), isNotNull);
      expect(Validators.email('@abc.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('senha curta é rejeitada', () {
      expect(Validators.password('123'), isNotNull);
    });
    test('senha com 6+ caracteres é aceita', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('senha!Segura'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('senhas diferentes são rejeitadas', () {
      expect(Validators.confirmPassword('abcdef', 'abcdeg'), isNotNull);
    });
    test('senhas iguais são aceitas', () {
      expect(Validators.confirmPassword('abcdef', 'abcdef'), isNull);
    });
  });

  group('Validators.vehicleYear', () {
    test('ano de fabricação válido', () {
      expect(Validators.vehicleYear('2018'), isNull);
      expect(Validators.vehicleYear('${DateTime.now().year}'), isNull);
    });
    test('ano inválido (futuro/alta)', () {
      final maxYear = DateTime.now().year + 1;
      expect(Validators.vehicleYear('${maxYear + 1}'), isNotNull);
      expect(Validators.vehicleYear('1850'), isNotNull);
      expect(Validators.vehicleYear('abcd'), isNotNull);
    });
  });

  group('Validators.mileage', () {
    test('quilometragem válida', () {
      expect(Validators.mileage('0'), isNull);
      expect(Validators.mileage('92450'), isNull);
    });
    test('quilometragem negativa é rejeitada', () {
      expect(Validators.mileage('-10'), isNotNull);
    });
    test('minha quilometragem com separador de milhar', () {
      expect(Validators.parseMileage('1.234'), 1234);
      expect(Validators.parseMileage('92.450'), 92450);
    });
  });

  group('Validators.money', () {
    test('valor monetário válido', () {
      expect(Validators.money('150'), isNull);
      expect(Validators.money('1.234,56'), isNull);
      expect(Validators.money('1234.56'), isNull);
    });
    test('valor negativo é rejeitado', () {
      expect(Validators.money('-10'), isNotNull);
    });
    test('parseMoney normaliza formatos BR', () {
      expect(Validators.parseMoney('1.234,56'), 1234.56);
      expect(Validators.parseMoney('1234.56'), 1234.56);
      expect(Validators.parseMoney('50'), 50.0);
    });
  });
}
