import { Inject, Injectable } from '@nestjs/common';

import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';
import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import type { CredentialCipher } from '@shared/application/ports/credential-cipher.port';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';
import type { TailscaleAuthKeyResponseDto } from '@modules/integrations/application/dtos/tailscale-auth-key-response.dto';
import type {
  IssueTailscaleAuthKeyError,
  IssueTailscaleAuthKeyUseCase,
} from '@modules/integrations/application/ports/in/issue-tailscale-auth-key.use-case';
import { TAILSCALE_GATEWAY } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import type {
  TailscaleApiCredential,
  TailscaleGateway,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

const AUTH_KEY_LIFETIME = '1h';
const AUTH_KEY_LIFETIME_MS = 60 * 60 * 1000;

@Injectable()
export class IssueTailscaleAuthKeyUseCaseImpl implements IssueTailscaleAuthKeyUseCase {
  constructor(
    @Inject(INTEGRATION_REPOSITORY) private readonly integrations: IntegrationRepository,
    @Inject(TAILSCALE_GATEWAY) private readonly tailscale: TailscaleGateway,
    @Inject(CREDENTIAL_CIPHER) private readonly cipher: CredentialCipher,
  ) {}

  async execute(input: OwnerQueryDto): Promise<Result<TailscaleAuthKeyResponseDto, IssueTailscaleAuthKeyError>> {
    const integration = await this.integrations.findByOwnerAndPlatform(
      input.ownerId,
      IntegrationPlatform.Tailscale,
    );
    if (!integration?.credential) {
      return Result.err(new IntegrationNotFoundException(IntegrationPlatform.Tailscale));
    }

    const credential = JSON.parse(this.cipher.decrypt(integration.credential)) as TailscaleApiCredential;
    const result = await this.tailscale.createAuthKey(credential.apiAccessToken, {
      reusable: false,
      ephemeral: true,
      expiryDuration: AUTH_KEY_LIFETIME,
    });
    if (result.isErr) {
      return Result.err(new ExternalProviderException('Tailscale', result.error.message));
    }

    return Result.ok({
      authKey: result.value,
      expiresAt: new Date(Date.now() + AUTH_KEY_LIFETIME_MS).toISOString(),
    });
  }
}
