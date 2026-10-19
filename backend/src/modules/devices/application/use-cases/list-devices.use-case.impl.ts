import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import type { ListDevicesDto } from '@modules/devices/application/dtos/list-devices.dto';
import { DeviceMapper } from '@modules/devices/application/mappers/device.mapper';
import type { ListDevicesUseCase } from '@modules/devices/application/ports/in/list-devices.use-case';

@Injectable()
export class ListDevicesUseCaseImpl implements ListDevicesUseCase {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async execute(input: ListDevicesDto): Promise<Result<DeviceResponseDto[], never>> {
    const devices = await this.devices.findAllByOwner(input.ownerId);
    return Result.ok(devices.map((device) => DeviceMapper.toResponse(device)));
  }
}
