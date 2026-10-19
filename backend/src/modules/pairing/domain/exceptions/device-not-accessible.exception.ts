import { EntityNotFoundException } from '@shared/domain/exceptions/domain.exception';

/**
 * Deliberadamente não distingue "esse dispositivo não existe" de "esse
 * dispositivo não é seu" — do ponto de vista de quem chamou, a resposta é a
 * mesma, e diferenciar vazaria pra um usuário não-dono que o ID existe.
 */
export class DeviceNotAccessibleException extends EntityNotFoundException {
  constructor(deviceId: string) {
    super(`Dispositivo ${deviceId} não encontrado.`);
  }
}
