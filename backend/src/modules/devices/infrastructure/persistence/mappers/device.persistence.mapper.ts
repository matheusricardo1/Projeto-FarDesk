import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import type { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

/** Forma do dispositivo no armazenamento — tipos primitivos, como uma linha de tabela. */
export interface DeviceRecord {
  id: string;
  ownerId: string;
  name: string;
  platform: DevicePlatform;
  status: DeviceStatus;
  lastHeartbeatAt: string | null;
  activeViewerCount: number;
}

export class DevicePersistenceMapper {
  static toRecord(device: Device): DeviceRecord {
    const snapshot = device.toSnapshot();
    return {
      id: snapshot.id.value,
      ownerId: snapshot.ownerId,
      name: snapshot.name,
      platform: snapshot.platform,
      status: snapshot.status,
      lastHeartbeatAt: snapshot.lastHeartbeatAt?.toISOString() ?? null,
      activeViewerCount: snapshot.activeViewerCount,
    };
  }

  static toDomain(record: DeviceRecord): Device {
    return Device.reconstruct({
      id: DeviceId.create(record.id),
      ownerId: record.ownerId,
      name: record.name,
      platform: record.platform,
      status: record.status,
      lastHeartbeatAt: record.lastHeartbeatAt ? new Date(record.lastHeartbeatAt) : null,
      activeViewerCount: record.activeViewerCount,
    });
  }
}
