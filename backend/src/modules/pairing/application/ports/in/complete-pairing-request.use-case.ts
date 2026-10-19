import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';

import type { PairingRequestActionDto } from '@modules/pairing/application/dtos/pairing-request-action.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import type { PairingRequestActionError } from '@modules/pairing/application/ports/in/ack-pairing-request.use-case';

export const COMPLETE_PAIRING_REQUEST_USE_CASE = Symbol('COMPLETE_PAIRING_REQUEST_USE_CASE');

/** O cliente chama isto depois que o handshake HTTPS com o host fechou. */
export type CompletePairingRequestUseCase = UseCase<
  PairingRequestActionDto,
  Result<PairingRequestResponseDto, PairingRequestActionError>
>;
