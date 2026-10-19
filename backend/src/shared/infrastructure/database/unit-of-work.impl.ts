import { Injectable } from '@nestjs/common';

import type { UnitOfWork } from '@shared/application/ports/unit-of-work.port';

/**
 * Enquanto a persistência é em memória não existe transação de verdade —
 * isto só executa o trabalho. Quando o Prisma entrar (`database/prisma/`),
 * a implementação real envolve `work` num `prisma.$transaction` e nenhum
 * caso de uso muda.
 */
@Injectable()
export class InMemoryUnitOfWork implements UnitOfWork {
  async runInTransaction<T>(work: () => Promise<T>): Promise<T> {
    return work();
  }
}
