import type { UseCase } from '@shared/application/ports/use-case.port';
import type { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import type { Result } from '@shared/domain/types/result';
import type { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import type { OwnerQueryDto } from '@modules/integrations/application/dtos/owner-query.dto';
import type { TailscaleDeviceResponseDto } from '@modules/integrations/application/dtos/tailscale-device-response.dto';

export const LIST_TAILSCALE_DEVICES_USE_CASE = Symbol('LIST_TAILSCALE_DEVICES_USE_CASE');

export type ListTailscaleDevicesError = IntegrationNotFoundException | ExternalProviderException;

/** Resolve o endereço Tailscale de um host quando um cliente quer se conectar a ele. */
export type ListTailscaleDevicesUseCase = UseCase<
  OwnerQueryDto,
  Result<TailscaleDeviceResponseDto[], ListTailscaleDevicesError>
>;
