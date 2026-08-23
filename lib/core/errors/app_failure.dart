/// Representa uma falha de negócio/infraestrutura com mensagem amigável
/// pronta para ser exibida ao usuário em pt-BR.
class AppFailure implements Exception {
  const AppFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
