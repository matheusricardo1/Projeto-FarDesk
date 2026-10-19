import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { DeviceNotAvailableException } from '@modules/devices/domain/exceptions/device-not-available.exception';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';

export const START_SESSION_USE_CASE = Symbol('START_SESSION_USE_CASE');

export type StartSessionError = DeviceAccessException | DeviceNotAvailableException;

/** O cliente escolheu "Conectar" num dispositivo. */
export type StartSessionUseCase = UseCase<DeviceActionDto, Result<DeviceResponseDto, StartSessionError>>;
