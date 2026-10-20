import { Inject, Injectable } from '@nestjs/common';

import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';
import { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import type { ConnectTailscaleIntegrationCommand } from '@modules/integrations/application/dtos/connect-tailscale-integration.dto';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';
import { IntegrationMapper } from '@modules/integrations/application/mappers/integration.mapper';
import type { ConnectTailscaleIntegrationUseCase } from '@modules/integrations/application/ports/in/connect-tailscale-integration.use-case';
import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import type { CredentialCipher } from '@shared/application/ports/credential-cipher.port';
import { TAILSCALE_GATEWAY } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import type { TailscaleGateway } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

/**
 * A credencial só é persistida depois de validada contra o provedor, e
 * sempre cifrada — o texto puro existe só durante esta execução.
 */
@Injectable()
export class ConnectTailscaleIntegrationUseCaseImpl implements ConnectTailscaleIntegrationUseCase {
  constructor(
    @Inject(INTEGRATION_REPOSITORY) private readonly integrations: IntegrationRepository,
    @Inject(TAILSCALE_GATEWAY) private readonly tailscale: TailscaleGateway,
    @Inject(CREDENTIAL_CIPHER) private readonly cipher: CredentialCipher,
  ) {}

  async execute(
    input: ConnectTailscaleIntegrationCommand,
  ): Promise<Result<IntegrationResponseDto, ExternalProviderException>> {
    const validation = await this.tailscale.validateAccessToken(input.apiAccessToken);
    if (validation.isErr) {
      return Result.err(new ExternalProviderException('Tailscale', validation.error.message));
    }

    const now = new Date();
    const credential = this.cipher.encrypt(JSON.stringify({ apiAccessToken: input.apiAccessToken }));

    const existing = await this.integrations.findByOwnerAndPlatform(
      input.ownerId,
      IntegrationPlatform.Tailscale,
    );
    const integration =
      existing ??
      Integration.connect({
        ownerId: input.ownerId,
        platform: IntegrationPlatform.Tailscale,
        credential,
        now,
      });
    if (existing) existing.rotateCredential(credential, now);

    await this.integrations.save(integration);
    return Result.ok(IntegrationMapper.toResponse(integration));
  }
}
