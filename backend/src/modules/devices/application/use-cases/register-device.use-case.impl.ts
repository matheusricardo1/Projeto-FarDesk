import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import type { RegisterDeviceCommand } from '@modules/devices/application/dtos/register-device.dto';
import { DeviceMapper } from '@modules/devices/application/mappers/device.mapper';
import type {
  RegisterDeviceError,
  RegisterDeviceUseCase,
} from '@modules/devices/application/ports/in/register-device.use-case';

/**
 * Idempotente de propósito: o cliente gera o `deviceId` uma única vez
 * (persistido localmente) e chama isso a cada login — se o device já
 * existe, só devolve ele sem duplicar nem sobrescrever nada.
 */
@Injectable()
export class RegisterDeviceUseCaseImpl implements RegisterDeviceUseCase {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async execute(input: RegisterDeviceCommand): Promise<Result<DeviceResponseDto, RegisterDeviceError>> {
    const existing = await this.devices.findById(DeviceId.create(input.deviceId));
    if (existing) {
      if (existing.ownerId !== input.ownerId) return Result.err(new NotDeviceOwnerException(input.deviceId));
      return Result.ok(DeviceMapper.toResponse(existing));
    }

    const device = Device.create({
      id: DeviceId.create(input.deviceId),
      ownerId: input.ownerId,
      name: input.name,
      platform: input.platform,
    });
    await this.devices.save(device);
    return Result.ok(DeviceMapper.toResponse(device));
  }
}
