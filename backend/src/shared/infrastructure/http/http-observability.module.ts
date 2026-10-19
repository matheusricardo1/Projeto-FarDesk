import { Module } from '@nestjs/common';
import type { MiddlewareConsumer, NestModule } from '@nestjs/common';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';

import { AllExceptionsFilter } from '@shared/infrastructure/http/all-exceptions.filter';
import { CorrelationIdMiddleware } from '@shared/infrastructure/http/correlation-id.middleware';
import { LoggingInterceptor } from '@shared/infrastructure/http/logging.interceptor';

/** O que toda requisição atravessa: id de correlação, log, tradução de exceção. */
@Module({
  providers: [
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
  ],
})
export class HttpObservabilityModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
