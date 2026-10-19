import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';

import type { PairingRequestActionDto } from '@modules/pairing/application/dtos/pairing-request-action.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import type { PairingRequestExpiredException } from '@modules/pairing/domain/exceptions/pairing-request-expired.exception';
import type { PairingRequestNotFoundException } from '@modules/pairing/domain/exceptions/pairing-request-not-found.exception';

export const ACK_PAIRING_REQUEST_USE_CASE = Symbol('ACK_PAIRING_REQUEST_USE_CASE');

export type PairingRequestActionError = PairingRequestNotFoundException | PairingRequestExpiredException;

/** O agente chama isto depois de submeter o PIN pro Sunshine local. */
export type AckPairingRequestUseCase = UseCase<
  PairingRequestActionDto,
  Result<PairingRequestResponseDto, PairingRequestActionError>
>;
