import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { DeviceNotHibernatingException } from '@modules/devices/domain/exceptions/device-not-hibernating.exception';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceOwnershipService } from '@modules/devices/domain/services/device-ownership.domain-service';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import { DeviceMapper } from '@modules/devices/application/mappers/device.mapper';
import type {
  RequestWakeError,
  RequestWakeUseCase,
} from '@modules/devices/application/ports/in/request-wake.use-case';

@Injectable()
export class RequestWakeUseCaseImpl implements RequestWakeUseCase {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async execute(input: DeviceActionDto): Promise<Result<DeviceResponseDto, RequestWakeError>> {
    const found = await this.devices.findById(DeviceId.create(input.deviceId));
    const owned = DeviceOwnershipService.ensureOwnedBy(found, input.deviceId, input.ownerId);
    if (owned.isErr) return Result.err(owned.error);

    const device = owned.value;
    try {
      device.requestWake();
    } catch (error) {
      if (error instanceof DeviceNotHibernatingException) return Result.err(error);
      throw error;
    }

    await this.devices.save(device);
    return Result.ok(DeviceMapper.toResponse(device));
  }
}
