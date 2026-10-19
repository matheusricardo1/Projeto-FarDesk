import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceOwnershipService } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import { DeviceMapper } from '@modules/devices/application/mappers/device.mapper';
import type { EndSessionUseCase } from '@modules/devices/application/ports/in/end-session.use-case';

@Injectable()
export class EndSessionUseCaseImpl implements EndSessionUseCase {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async execute(input: DeviceActionDto): Promise<Result<DeviceResponseDto, DeviceAccessException>> {
    const found = await this.devices.findById(DeviceId.create(input.deviceId));
    const owned = DeviceOwnershipService.ensureOwnedBy(found, input.deviceId, input.ownerId);
    if (owned.isErr) return Result.err(owned.error);

    const device = owned.value;
    device.endSession();
    await this.devices.save(device);
    return Result.ok(DeviceMapper.toResponse(device));
  }
}
