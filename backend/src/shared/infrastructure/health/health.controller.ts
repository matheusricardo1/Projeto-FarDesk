import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, MemoryHealthIndicator } from '@nestjs/terminus';

import { Public } from '@shared/infrastructure/http/public.decorator';

const MAX_HEAP_BYTES = 300 * 1024 * 1024;

/** Liveness pra monitoramento externo. Ganha indicadores de banco quando houver um. */
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly memory: MemoryHealthIndicator,
  ) {}

  @Public()
  @Get()
  @HealthCheck()
  check() {
    return this.health.check([() => this.memory.checkHeap('heap', MAX_HEAP_BYTES)]);
  }
}
