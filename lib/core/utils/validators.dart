/// Validadores de formulários com mensagens em pt-BR.
/// Retornam `null` quando válidos ou a mensagem de erro.
abstract final class Validators {
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
  );

  static String? required(String? value, [String field = 'Campo']) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório.';
    return null;
  }

  static String? email(String? value) {
    if (required(value, 'E-mail') != null) return 'E-mail é obrigatório.';
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória.';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirme sua senha.';
    if (value != password) return 'As senhas não coincidem.';
    return null;
  }

  static String? personName(String? value) {
    if (required(value, 'Nome') != null) return 'Nome é obrigatório.';
    if (value!.trim().length < 2) return 'Informe seu nome completo.';
    return null;
  }

  static String? vehicleYear(String? value) {
    if (required(value, 'Ano') != null) return 'Ano é obrigatório.';
    final year = int.tryParse(value!);
    final maxYear = DateTime.now().year + 1;
    if (year == null || year < 1900 || year > maxYear) {
      return 'Informe um ano válido (1900 a $maxYear).';
    }
    return null;
  }

  static String? mileage(String? value, {bool allowEmpty = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : 'Quilometragem é obrigatória.';
    }
    final km = int.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
    if (km == null || km < 0) return 'Quilometragem inválida.';
    return null;
  }

  static String? money(String? value, {bool allowEmpty = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : 'Valor é obrigatório.';
    }
    final parsed = parseMoney(value);
    if (parsed == null || parsed < 0) return 'Informe um valor válido.';
    return null;
  }

  /// Converte "1.234,56" / "1234.56" / "1234" em double, ou null se inválido.
  /// Regras:
  /// - Se houver vírgula: o formato é BR (ponto = milhar, vírgula = decimal).
  /// - Se houver ponto e for o último separador com 1-3 casas após ele e sem vírgula:
  ///   pode ser decimal (ex.: 1234.56) ou milhar (1.234). Desambiguamos:
  ///   `1.234,56` tem vírgula → BR. `1234.56` não tem vírgula → decimal.
  static double? parseMoney(String value) {
    var v = value.trim().replaceAll('R\$', '').trim();
    if (v.isEmpty) return null;
    if (v.contains(',')) {
      v = v.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Sem vírgula: trata ponto como decimal quando vier no final.
      final lastDot = v.lastIndexOf('.');
      if (lastDot > 0) {
        final tail = v.substring(lastDot + 1);
        // 1.234 (sem vírgula) ambíguo: assumimos decimal (mais comum).
        if (tail.length <= 3 && int.tryParse(tail) != null) {
          // já é o formato decimal padrão; não remover o ponto.
        } else {
          // ponto como separador de milhar.
          v = v.replaceAll('.', '');
        }
      }
    }
    return double.tryParse(v);
  }

  static int? parseMileage(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// Verifica se a placa segue padrão Mercosul (ABC1D23) ou antigo (ABC-1234 / ABC1234).
  /// Usado como aviso educativo/orientativo, não bloqueio.
  static bool isBrazilianPlate(String value) {
    final clean = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length != 7) return false;
    final mercosulRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    final oldRegex = RegExp(r'^[A-Z]{3}[0-9]{4}$');
    return mercosulRegex.hasMatch(clean) || oldRegex.hasMatch(clean);
  }
}
