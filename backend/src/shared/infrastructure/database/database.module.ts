import { Global, Module } from '@nestjs/common';

import { UNIT_OF_WORK } from '@shared/application/ports/unit-of-work.port';
import { InMemoryUnitOfWork } from '@shared/infrastructure/database/unit-of-work.impl';
import { PrismaService } from '@shared/infrastructure/database/prisma.service';

@Global()
@Module({
  providers: [{ provide: UNIT_OF_WORK, useClass: InMemoryUnitOfWork }, PrismaService],
  exports: [UNIT_OF_WORK, PrismaService],
})
export class DatabaseModule {}
