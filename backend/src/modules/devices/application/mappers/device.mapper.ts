import type { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import type { HeartbeatResponseDto } from '@modules/devices/application/dtos/heartbeat-response.dto';

export class DeviceMapper {
  static toResponse(device: Device): DeviceResponseDto {
    return {
      id: device.id.value,
      name: device.name,
      platform: device.platform,
      status: device.status,
      activeViewerCount: device.activeViewerCount,
      lastHeartbeatAt: device.lastHeartbeatAt?.toISOString() ?? null,
    };
  }

  static toHeartbeatResponse(device: Device): HeartbeatResponseDto {
    return {
      device: DeviceMapper.toResponse(device),
      nextHeartbeatIntervalSeconds: device.nextHeartbeatIntervalSeconds(),
    };
  }
}
