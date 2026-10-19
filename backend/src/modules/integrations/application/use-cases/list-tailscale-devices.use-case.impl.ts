import { Inject, Injectable } from '@nestjs/common';

import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';
import { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';
import type { TailscaleDeviceResponseDto } from '@modules/integrations/application/dtos/tailscale-device-response.dto';
import { TailscaleDeviceMapper } from '@modules/integrations/application/mappers/tailscale-device.mapper';
import type {
  ListTailscaleDevicesError,
  ListTailscaleDevicesUseCase,
} from '@modules/integrations/application/ports/in/list-tailscale-devices.use-case';
import { CREDENTIAL_CIPHER } from '@modules/integrations/application/ports/out/credential-cipher.port';
import type { CredentialCipher } from '@modules/integrations/application/ports/out/credential-cipher.port';
import { TAILSCALE_GATEWAY } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import type {
  TailscaleGateway,
  TailscaleOAuthCredential,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

/** O token é pedido de novo a cada uso, nunca guardado — só a credencial cifrada persiste. */
@Injectable()
export class ListTailscaleDevicesUseCaseImpl implements ListTailscaleDevicesUseCase {
  constructor(
    @Inject(INTEGRATION_REPOSITORY) private readonly integrations: IntegrationRepository,
    @Inject(TAILSCALE_GATEWAY) private readonly tailscale: TailscaleGateway,
    @Inject(CREDENTIAL_CIPHER) private readonly cipher: CredentialCipher,
  ) {}

  async execute(
    input: OwnerQueryDto,
  ): Promise<Result<TailscaleDeviceResponseDto[], ListTailscaleDevicesError>> {
    const integration = await this.integrations.findByOwnerAndPlatform(
      input.ownerId,
      IntegrationPlatform.Tailscale,
    );
    if (!integration?.credential)
      return Result.err(new IntegrationNotFoundException(IntegrationPlatform.Tailscale));

    const credential = JSON.parse(this.cipher.decrypt(integration.credential)) as TailscaleOAuthCredential;

    const tokenResult = await this.tailscale.exchangeForAccessToken(credential);
    if (tokenResult.isErr) {
      integration.markError(tokenResult.error.message);
      await this.integrations.save(integration);
      return Result.err(new ExternalProviderException('Tailscale', tokenResult.error.message));
    }

    const devicesResult = await this.tailscale.listDevices(tokenResult.value);
    if (devicesResult.isErr) {
      return Result.err(new ExternalProviderException('Tailscale', devicesResult.error.message));
    }

    integration.markValidated(new Date());
    await this.integrations.save(integration);
    return Result.ok(devicesResult.value.map((device) => TailscaleDeviceMapper.toResponse(device)));
  }
}
