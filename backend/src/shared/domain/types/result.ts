/**
 * Resultado de uma operação que pode falhar. Casos de uso retornam isso pra
 * erro de negócio esperado; só bug ou infra fora do ar vira `throw`.
 * Espelha o `Result<T>` do app Flutter (lib/core/result.dart).
 */
export class Result<T, E = Error> {
  private constructor(
    private readonly success: boolean,
    private readonly _value: T | undefined,
    private readonly _error: E | undefined,
  ) {}

  static ok<T, E = Error>(value: T): Result<T, E> {
    return new Result<T, E>(true, value, undefined);
  }

  static err<T, E = Error>(error: E): Result<T, E> {
    return new Result<T, E>(false, undefined, error);
  }

  get isOk(): boolean {
    return this.success;
  }

  get isErr(): boolean {
    return !this.success;
  }

  get value(): T {
    if (!this.success) throw new Error('Tentativa de ler o valor de um Result de erro.');
    return this._value as T;
  }

  get error(): E {
    if (this.success) throw new Error('Tentativa de ler o erro de um Result de sucesso.');
    return this._error as E;
  }

  map<U>(fn: (value: T) => U): Result<U, E> {
    return this.success ? Result.ok(fn(this._value as T)) : Result.err(this._error as E);
  }
}
