import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';

import { RateLimitGuard } from '@shared/infrastructure/security/rate-limit.guard';

/** Rate limit global: 100 req/min por IP, inclusive nas rotas públicas de login. */
@Module({
  providers: [{ provide: APP_GUARD, useClass: RateLimitGuard }],
})
export class SecurityModule {}
