import { BusinessRuleViolationException } from '@shared/domain/exceptions/domain.exception';

export class NotDeviceOwnerException extends BusinessRuleViolationException {
  constructor(deviceId: string) {
    super(`Você não é dono do dispositivo ${deviceId}.`);
  }
}
