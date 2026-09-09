/// Falha vinda da API, já com a mensagem pronta para o usuário.
///
/// A camada de API devolve `ApiResponse` e nunca lança; o repositório, por
/// outro lado, expõe valores (`List<Purchase>`, e não um envelope). Esta
/// exceção é a ponte entre os dois contratos.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
