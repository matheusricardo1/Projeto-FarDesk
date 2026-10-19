import { Inject, Injectable } from '@nestjs/common';

import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DeviceLookupGateway } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';

/**
 * Único ponto do módulo que conhece `devices` de verdade — lê o repositório
 * dele direto porque é o mesmo processo. Se `devices` virar um serviço
 * separado algum dia, só este arquivo muda.
 */
@Injectable()
export class DeviceRepositoryLookupGateway implements DeviceLookupGateway {
  constructor(@Inject(DEVICE_REPOSITORY) private readonly devices: DeviceRepository) {}

  async isOwnedByAccount(deviceId: string, ownerId: string): Promise<boolean> {
    const device = await this.devices.findById(DeviceId.create(deviceId));
    return device !== null && device.ownerId === ownerId;
  }
}
