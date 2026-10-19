import { BusinessRuleViolationException } from '@shared/domain/exceptions/domain.exception';

export class DeviceNotAvailableException extends BusinessRuleViolationException {
  constructor(deviceId: string, currentStatus: string) {
    super(`Dispositivo ${deviceId} não está disponível pra conectar agora (status: ${currentStatus}).`);
  }
}
