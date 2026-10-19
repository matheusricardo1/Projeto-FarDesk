import type { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import type { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';

export const DEVICE_REPOSITORY = Symbol('DEVICE_REPOSITORY');

/** Porta de persistência. Implementação em `infrastructure/persistence`. */
export interface DeviceRepository {
  findById(id: DeviceId): Promise<Device | null>;
  findAllByOwner(ownerId: string): Promise<Device[]>;
  save(device: Device): Promise<void>;
}
