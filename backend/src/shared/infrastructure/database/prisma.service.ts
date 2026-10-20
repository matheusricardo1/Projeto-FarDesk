import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

import { AppConfigService } from '@shared/infrastructure/config/app-config.service';

/**
 * Único ponto de acesso ao Postgres. O Prisma 7 não lê mais a connection
 * string do schema — ela entra via `adapter`, montado aqui com a
 * `DATABASE_URL` (pooler transacional do Supabase, porta 6543): é a certa
 * pro runtime, que faz muitas queries curtas; migrações usam a `DIRECT_URL`
 * (porta 5432) só pelo `prisma.config.ts`, nunca por aqui.
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor(config: AppConfigService) {
    super({ adapter: new PrismaPg({ connectionString: config.databaseUrl }) });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
