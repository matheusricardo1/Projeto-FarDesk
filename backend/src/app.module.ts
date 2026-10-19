import { Module } from '@nestjs/common';

import { AuthModule } from '@modules/auth/auth.module';
import { DevicesModule } from '@modules/devices/devices.module';
import { IntegrationsModule } from '@modules/integrations/integrations.module';
import { PairingModule } from '@modules/pairing/pairing.module';
import { AppConfigModule } from '@shared/infrastructure/config/config.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { HealthModule } from '@shared/infrastructure/health/health.module';
import { HttpObservabilityModule } from '@shared/infrastructure/http/http-observability.module';
import { MessagingModule } from '@shared/infrastructure/messaging/messaging.module';
import { SecurityModule } from '@shared/infrastructure/security/security.module';

/**
 * Ordem importa: config primeiro (todo o resto lê dela) e `SecurityModule`
 * antes de `AuthModule` (rate limit roda antes da checagem de JWT).
 */
@Module({
  imports: [
    AppConfigModule,
    DatabaseModule,
    MessagingModule,
    HttpObservabilityModule,
    SecurityModule,
    HealthModule,
    AuthModule,
    DevicesModule,
    IntegrationsModule,
    PairingModule,
  ],
})
export class AppModule {}
