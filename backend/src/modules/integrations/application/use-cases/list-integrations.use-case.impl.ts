import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { INTEGRATION_REPOSITORY } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';
import { IntegrationMapper } from '@modules/integrations/application/mappers/integration.mapper';
import type { ListIntegrationsUseCase } from '@modules/integrations/application/ports/in/list-integrations.use-case';

@Injectable()
export class ListIntegrationsUseCaseImpl implements ListIntegrationsUseCase {
  constructor(@Inject(INTEGRATION_REPOSITORY) private readonly integrations: IntegrationRepository) {}

  async execute(input: OwnerQueryDto): Promise<Result<IntegrationResponseDto[], never>> {
    const integrations = await this.integrations.findAllByOwner(input.ownerId);
    return Result.ok(integrations.map((integration) => IntegrationMapper.toResponse(integration)));
  }
}
