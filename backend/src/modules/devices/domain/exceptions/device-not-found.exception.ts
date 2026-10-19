import { EntityNotFoundException } from '@shared/domain/exceptions/domain.exception';

export class DeviceNotFoundException extends EntityNotFoundException {
  constructor(deviceId: string) {
    super(`Dispositivo ${deviceId} não encontrado.`);
  }
}
