import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';

import type { CreatePairingRequestCommand } from '@modules/pairing/application/dtos/create-pairing-request.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import type { DeviceNotAccessibleException } from '@modules/pairing/domain/exceptions/device-not-accessible.exception';

export const CREATE_PAIRING_REQUEST_USE_CASE = Symbol('CREATE_PAIRING_REQUEST_USE_CASE');

/** O cliente chama isto antes de iniciar o handshake HTTPS direto com o host. */
export type CreatePairingRequestUseCase = UseCase<
  CreatePairingRequestCommand,
  Result<PairingRequestResponseDto, DeviceNotAccessibleException>
>;
