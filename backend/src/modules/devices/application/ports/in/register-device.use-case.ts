import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import type { RegisterDeviceCommand } from '@modules/devices/application/dtos/register-device.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';

export const REGISTER_DEVICE_USE_CASE = Symbol('REGISTER_DEVICE_USE_CASE');

export type RegisterDeviceError = NotDeviceOwnerException;

export type RegisterDeviceUseCase = UseCase<RegisterDeviceCommand, Result<DeviceResponseDto, RegisterDeviceError>>;
