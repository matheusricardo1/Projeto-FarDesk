import type { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import type { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

/** Forma do dispositivo fora da aplicação — o agregado nunca sai daqui cru. */
export interface DeviceResponseDto {
  id: string;
  name: string;
  platform: DevicePlatform;
  status: DeviceStatus;
  activeViewerCount: number;
  lastHeartbeatAt: string | null;
}
