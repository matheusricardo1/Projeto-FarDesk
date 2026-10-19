import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import { DevicePersistenceMapper } from '@modules/devices/infrastructure/persistence/mappers/device.persistence.mapper';

describe('DevicePersistenceMapper', () => {
  it('ida e volta preserva o agregado', () => {
    const device = Device.create({ ownerId: 'owner-1', name: 'PC', platform: DevicePlatform.Linux });
    device.recordHeartbeat(new Date('2026-01-01T00:00:00Z'));

    const restored = DevicePersistenceMapper.toDomain(DevicePersistenceMapper.toRecord(device));

    expect(restored.equals(device)).toBe(true);
    expect(restored.toSnapshot()).toEqual(device.toSnapshot());
  });
});
