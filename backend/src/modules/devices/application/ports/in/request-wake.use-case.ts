import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { DeviceNotHibernatingException } from '@modules/devices/domain/exceptions/device-not-hibernating.exception';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';

export const REQUEST_WAKE_USE_CASE = Symbol('REQUEST_WAKE_USE_CASE');

export type RequestWakeError = DeviceAccessException | DeviceNotHibernatingException;

export type RequestWakeUseCase = UseCase<DeviceActionDto, Result<DeviceResponseDto, RequestWakeError>>;
