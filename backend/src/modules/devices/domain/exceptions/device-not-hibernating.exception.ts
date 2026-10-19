import { BusinessRuleViolationException } from '@shared/domain/exceptions/domain.exception';

export class DeviceNotHibernatingException extends BusinessRuleViolationException {
  constructor(deviceId: string, currentStatus: string) {
    super(`Dispositivo ${deviceId} não está hibernando — não há o que acordar (status: ${currentStatus}).`);
  }
}
