import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';

import type { DeviceOwnerQueryDto } from '@modules/pairing/application/dtos/device-owner-query.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import type { DeviceNotAccessibleException } from '@modules/pairing/domain/exceptions/device-not-accessible.exception';

export const GET_PENDING_PAIRING_REQUEST_USE_CASE = Symbol('GET_PENDING_PAIRING_REQUEST_USE_CASE');

/** O agente do host faz polling nisto — `null` quando não há nada esperando. */
export type GetPendingPairingRequestUseCase = UseCase<
  DeviceOwnerQueryDto,
  Result<PairingRequestResponseDto | null, DeviceNotAccessibleException>
>;
