import { Inject, Injectable } from '@nestjs/common';

import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import type { CredentialCipher } from '@shared/application/ports/credential-cipher.port';
import { Result } from '@shared/domain/types/result';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import type { HostCredential } from '@modules/devices/application/dtos/host-credential.dto';
import type {
  GetHostCredentialCommand,
  GetHostCredentialUseCase,
} from '@modules/devices/application/ports/in/get-host-credential.use-case';

@Injectable()
export class GetHostCredentialUseCaseImpl implements GetHostCredentialUseCase {
  constructor(
    @Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository,
    @Inject(CREDENTIAL_CIPHER) private readonly cipher: CredentialCipher,
  ) {}

  async execute(input: GetHostCredentialCommand): Promise<Result<HostCredential | null, NotDeviceOwnerException>> {
    const device = await this.devices.findById(DeviceId.create(input.deviceId));
    if (!device || device.ownerId !== input.ownerId) {
      return Result.err(new NotDeviceOwnerException(input.deviceId));
    }
    if (!device.hostCredential) return Result.ok(null);

    const decoded = JSON.parse(this.cipher.decrypt(device.hostCredential)) as Partial<HostCredential>;
    if (typeof decoded.username !== 'string' || typeof decoded.password !== 'string') {
      throw new Error('Credencial do host armazenada em formato inválido.');
    }
    return Result.ok({ username: decoded.username, password: decoded.password });
  }
}
