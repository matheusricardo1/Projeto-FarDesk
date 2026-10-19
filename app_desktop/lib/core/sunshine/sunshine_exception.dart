/// Erro de protocolo ao falar com um host Sunshine — rede, XML malformado,
/// ou o host recusando a operação (status code/message da própria resposta XML).
class SunshineException implements Exception {
  const SunshineException(this.message);

  final String message;

  @override
  String toString() => 'SunshineException: $message';
}
