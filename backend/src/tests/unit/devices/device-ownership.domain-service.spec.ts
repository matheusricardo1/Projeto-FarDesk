import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DeviceNotFoundException } from '@modules/devices/domain/exceptions/device-not-found.exception';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import { DeviceOwnershipService } from '@modules/devices/domain/services/device-ownership.domain-service';
import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';

describe('DeviceOwnershipService', () => {
  const device = Device.create({ ownerId: 'owner-1', name: 'PC', platform: DevicePlatform.Windows });

  it('aceita o dono', () => {
    expect(DeviceOwnershipService.ensureOwnedBy(device, device.id.value, 'owner-1').value).toBe(device);
  });

  it('recusa outra conta', () => {
    expect(DeviceOwnershipService.ensureOwnedBy(device, device.id.value, 'owner-2').error).toBeInstanceOf(
      NotDeviceOwnerException,
    );
  });

  it('recusa dispositivo inexistente', () => {
    expect(DeviceOwnershipService.ensureOwnedBy(null, 'x', 'owner-1').error).toBeInstanceOf(
      DeviceNotFoundException,
    );
  });
});
