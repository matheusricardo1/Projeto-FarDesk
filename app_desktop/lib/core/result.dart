/// Resultado de uma operação que pode falhar. Repositórios retornam isso em
/// vez de lançar exceção, então a camada de apresentação sempre trata sucesso
/// e erro de forma explícita (via `switch`/pattern matching).
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Object error;
}
