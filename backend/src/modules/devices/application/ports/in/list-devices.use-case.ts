import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import type { ListDevicesDto } from '@modules/devices/application/dtos/list-devices.dto';

export const LIST_DEVICES_USE_CASE = Symbol('LIST_DEVICES_USE_CASE');

export type ListDevicesUseCase = UseCase<ListDevicesDto, Result<DeviceResponseDto[], never>>;
