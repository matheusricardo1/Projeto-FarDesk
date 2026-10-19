/// Erro de uma chamada HTTP pro backend do FarDesk — guarda o status code
/// pra quem tratar o erro poder diferenciar "não encontrado" de "sem
/// permissão" de "erro do servidor" sem reparsear a mensagem.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
