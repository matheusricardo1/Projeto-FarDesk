import type { UseCase } from '@shared/application/ports/use-case.port';
import type { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import type { Result } from '@shared/domain/types/result';
import type { ConnectTailscaleIntegrationCommand } from '@modules/integrations/application/dtos/connect-tailscale-integration.dto';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';

export const CONNECT_TAILSCALE_INTEGRATION_USE_CASE = Symbol('CONNECT_TAILSCALE_INTEGRATION_USE_CASE');

export type ConnectTailscaleIntegrationUseCase = UseCase<
  ConnectTailscaleIntegrationCommand,
  Result<IntegrationResponseDto, ExternalProviderException>
>;
