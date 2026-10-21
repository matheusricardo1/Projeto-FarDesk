import type { UseCase } from '@shared/application/ports/use-case.port';
import type { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import type { Result } from '@shared/domain/types/result';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';
import type { TailscaleAuthKeyResponseDto } from '@modules/integrations/application/dtos/tailscale-auth-key-response.dto';
import type { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';

export const ISSUE_TAILSCALE_AUTH_KEY_USE_CASE = Symbol('ISSUE_TAILSCALE_AUTH_KEY_USE_CASE');

export type IssueTailscaleAuthKeyError = IntegrationNotFoundException | ExternalProviderException;

export type IssueTailscaleAuthKeyUseCase = UseCase<
  OwnerQueryDto,
  Result<TailscaleAuthKeyResponseDto, IssueTailscaleAuthKeyError>
>;
