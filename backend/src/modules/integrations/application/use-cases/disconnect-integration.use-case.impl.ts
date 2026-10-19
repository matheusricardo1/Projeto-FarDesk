import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { DisconnectIntegrationDto } from '@modules/integrations/application/dtos/disconnect-integration.dto';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';
import { IntegrationMapper } from '@modules/integrations/application/mappers/integration.mapper';
import type { DisconnectIntegrationUseCase } from '@modules/integrations/application/ports/in/disconnect-integration.use-case';

@Injectable()
export class DisconnectIntegrationUseCaseImpl implements DisconnectIntegrationUseCase {
  constructor(@Inject(INTEGRATION_REPOSITORY) private readonly integrations: IntegrationRepository) {}

  async execute(
    input: DisconnectIntegrationDto,
  ): Promise<Result<IntegrationResponseDto, IntegrationNotFoundException>> {
    const integration = await this.integrations.findByOwnerAndPlatform(input.ownerId, input.platform);
    if (!integration) return Result.err(new IntegrationNotFoundException(input.platform));

    integration.disconnect();
    await this.integrations.save(integration);
    return Result.ok(IntegrationMapper.toResponse(integration));
  }
}
