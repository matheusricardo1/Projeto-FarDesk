import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import type { DisconnectIntegrationDto } from '@modules/integrations/application/dtos/disconnect-integration.dto';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';

export const DISCONNECT_INTEGRATION_USE_CASE = Symbol('DISCONNECT_INTEGRATION_USE_CASE');

export type DisconnectIntegrationUseCase = UseCase<
  DisconnectIntegrationDto,
  Result<IntegrationResponseDto, IntegrationNotFoundException>
>;
