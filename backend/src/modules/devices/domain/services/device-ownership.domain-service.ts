import { Result } from '@shared/domain/types/result';
import type { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DeviceNotFoundException } from '@modules/devices/domain/exceptions/device-not-found.exception';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';

export type DeviceAccessException = DeviceNotFoundException | NotDeviceOwnerException;

/**
 * Regra "só o dono opera o próprio dispositivo" — não pertence a um método
 * do agregado porque precisa lidar com o dispositivo nem existir. Pura:
 * quem busca no repositório é o caso de uso.
 */
export class DeviceOwnershipService {
  static ensureOwnedBy(
    device: Device | null,
    deviceId: string,
    ownerId: string,
  ): Result<Device, DeviceAccessException> {
    if (!device) return Result.err(new DeviceNotFoundException(deviceId));
    if (device.ownerId !== ownerId) return Result.err(new NotDeviceOwnerException(deviceId));
    return Result.ok(device);
  }
}
