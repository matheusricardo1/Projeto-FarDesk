import { Injectable, Module } from '@nestjs/common';
import type { DynamicModule } from '@nestjs/common';

/**
 * Só pros testes de integração. O `@nestjs/throttler` faz um `require()`
 * interno de `@nestjs/common` (ESM-only), ponte CJS→ESM que o Jest não
 * suporta — limitação do Jest, não do app: `node dist/main.js` com o pacote
 * real funciona. Mapeado via `moduleNameMapper` em `jest-e2e.json`.
 */
@Module({})
export class ThrottlerModule {
  static forRoot(): DynamicModule {
    return { module: ThrottlerModule };
  }
}

@Injectable()
export class ThrottlerGuard {
  canActivate(): boolean {
    return true;
  }
}
