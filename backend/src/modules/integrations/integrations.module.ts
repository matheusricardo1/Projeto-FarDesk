import { Module } from '@nestjs/common';

import { CONNECT_TAILSCALE_INTEGRATION_USE_CASE } from '@modules/integrations/application/ports/in/connect-tailscale-integration.use-case';
import { DISCONNECT_INTEGRATION_USE_CASE } from '@modules/integrations/application/ports/in/disconnect-integration.use-case';
import { LIST_INTEGRATIONS_USE_CASE } from '@modules/integrations/application/ports/in/list-integrations.use-case';
import { LIST_TAILSCALE_DEVICES_USE_CASE } from '@modules/integrations/application/ports/in/list-tailscale-devices.use-case';
import { ISSUE_TAILSCALE_AUTH_KEY_USE_CASE } from '@modules/integrations/application/ports/in/issue-tailscale-auth-key.use-case';
import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import { TAILSCALE_GATEWAY } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import { ConnectTailscaleIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/connect-tailscale-integration.use-case.impl';
import { DisconnectIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/disconnect-integration.use-case.impl';
import { ListIntegrationsUseCaseImpl } from '@modules/integrations/application/use-cases/list-integrations.use-case.impl';
import { ListTailscaleDevicesUseCaseImpl } from '@modules/integrations/application/use-cases/list-tailscale-devices.use-case.impl';
import { IssueTailscaleAuthKeyUseCaseImpl } from '@modules/integrations/application/use-cases/issue-tailscale-auth-key.use-case.impl';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import { IntegrationsController } from '@modules/integrations/infrastructure/http/integrations.controller';
import { IntegrationEventsListener } from '@modules/integrations/infrastructure/messaging/integration-events.listener';
import { PrismaIntegrationRepository } from '@modules/integrations/infrastructure/persistence/integration.repository.prisma';
import { TailscaleApiGateway } from '@modules/integrations/infrastructure/platforms/tailscale/tailscale-api.gateway';
import { AesGcmCredentialCipher } from '@shared/infrastructure/security/aes-gcm-credential-cipher';

@Module({
  controllers: [IntegrationsController],
  providers: [
    { provide: LIST_INTEGRATIONS_USE_CASE, useClass: ListIntegrationsUseCaseImpl },
    { provide: CONNECT_TAILSCALE_INTEGRATION_USE_CASE, useClass: ConnectTailscaleIntegrationUseCaseImpl },
    { provide: DISCONNECT_INTEGRATION_USE_CASE, useClass: DisconnectIntegrationUseCaseImpl },
    { provide: LIST_TAILSCALE_DEVICES_USE_CASE, useClass: ListTailscaleDevicesUseCaseImpl },
    { provide: ISSUE_TAILSCALE_AUTH_KEY_USE_CASE, useClass: IssueTailscaleAuthKeyUseCaseImpl },
    { provide: INTEGRATION_REPOSITORY, useClass: PrismaIntegrationRepository },
    { provide: CREDENTIAL_CIPHER, useClass: AesGcmCredentialCipher },
    { provide: TAILSCALE_GATEWAY, useClass: TailscaleApiGateway },
    IntegrationEventsListener,
  ],
})
export class IntegrationsModule {}
