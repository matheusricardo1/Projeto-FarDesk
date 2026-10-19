import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';

export const LIST_INTEGRATIONS_USE_CASE = Symbol('LIST_INTEGRATIONS_USE_CASE');

export type ListIntegrationsUseCase = UseCase<OwnerQueryDto, Result<IntegrationResponseDto[], never>>;
