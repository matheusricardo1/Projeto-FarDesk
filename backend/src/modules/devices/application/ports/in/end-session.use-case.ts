import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';

export const END_SESSION_USE_CASE = Symbol('END_SESSION_USE_CASE');

export type EndSessionUseCase = UseCase<DeviceActionDto, Result<DeviceResponseDto, DeviceAccessException>>;
