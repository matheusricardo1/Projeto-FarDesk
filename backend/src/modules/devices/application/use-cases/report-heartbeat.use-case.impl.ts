import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceOwnershipService } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { HeartbeatResponseDto } from '@modules/devices/application/dtos/heartbeat-response.dto';
import type { ReportHeartbeatDto } from '@modules/devices/application/dtos/report-heartbeat.dto';
import { DeviceMapper } from '@modules/devices/application/mappers/device.mapper';
import type { ReportHeartbeatUseCase } from '@modules/devices/application/ports/in/report-heartbeat.use-case';

@Injectable()
export class ReportHeartbeatUseCaseImpl implements ReportHeartbeatUseCase {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async execute(input: ReportHeartbeatDto): Promise<Result<HeartbeatResponseDto, DeviceAccessException>> {
    const found = await this.devices.findById(DeviceId.create(input.deviceId));
    const owned = DeviceOwnershipService.ensureOwnedBy(found, input.deviceId, input.ownerId);
    if (owned.isErr) return Result.err(owned.error);

    const device = owned.value;
    device.recordHeartbeat(input.at ?? new Date());
    await this.devices.save(device);
    return Result.ok(DeviceMapper.toHeartbeatResponse(device));
  }
}
