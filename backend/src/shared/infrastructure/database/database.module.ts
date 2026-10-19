import { Global, Module } from '@nestjs/common';

import { UNIT_OF_WORK } from '@shared/application/ports/unit-of-work.port';
import { InMemoryUnitOfWork } from '@shared/infrastructure/database/unit-of-work.impl';

@Global()
@Module({
  providers: [{ provide: UNIT_OF_WORK, useClass: InMemoryUnitOfWork }],
  exports: [UNIT_OF_WORK],
})
export class DatabaseModule {}
