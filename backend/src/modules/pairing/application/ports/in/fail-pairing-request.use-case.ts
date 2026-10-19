import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';

import type { FailPairingRequestDto } from '@modules/pairing/application/dtos/pairing-request-action.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import type { PairingRequestNotFoundException } from '@modules/pairing/domain/exceptions/pairing-request-not-found.exception';

export const FAIL_PAIRING_REQUEST_USE_CASE = Symbol('FAIL_PAIRING_REQUEST_USE_CASE');

/** Cliente ou agente chamam isto quando o pareamento não deu certo (PIN errado, timeout local, etc). */
export type FailPairingRequestUseCase = UseCase<
  FailPairingRequestDto,
  Result<PairingRequestResponseDto, PairingRequestNotFoundException>
>;
