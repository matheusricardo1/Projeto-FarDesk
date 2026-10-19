export const UNIT_OF_WORK = Symbol('UNIT_OF_WORK');

/**
 * Garante que um caso de uso que persiste mais de um agregado faça isso de
 * forma atômica — ou tudo é salvo, ou nada é. A implementação concreta
 * decide como (transação do banco, por exemplo).
 */
export interface UnitOfWork {
  runInTransaction<T>(work: () => Promise<T>): Promise<T>;
}
