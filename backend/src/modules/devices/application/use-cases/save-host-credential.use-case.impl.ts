import { Inject, Injectable } from '@nestjs/common';

import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import type { CredentialCipher } from '@shared/application/ports/credential-cipher.port';
import { Result } from '@shared/domain/types/result';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import type {
  SaveHostCredentialCommand,
  SaveHostCredentialUseCase,
} from '@modules/devices/application/ports/in/save-host-credential.use-case';

@Injectable()
export class SaveHostCredentialUseCaseImpl implements SaveHostCredentialUseCase {
  constructor(
    @Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository,
    @Inject(CREDENTIAL_CIPHER) private readonly cipher: CredentialCipher,
  ) {}

  async execute(input: SaveHostCredentialCommand): Promise<Result<void, NotDeviceOwnerException>> {
    const device = await this.devices.findById(DeviceId.create(input.deviceId));
    if (!device || device.ownerId !== input.ownerId) {
      return Result.err(new NotDeviceOwnerException(input.deviceId));
    }

    device.recordHostCredential(this.cipher.encrypt(JSON.stringify(input.credential)));
    await this.devices.save(device);
    return Result.ok(undefined);
  }
}
