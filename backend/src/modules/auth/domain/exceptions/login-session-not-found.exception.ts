import { EntityNotFoundException } from '@shared/domain/exceptions/domain.exception';

export class LoginSessionNotFoundException extends EntityNotFoundException {
  constructor(sessionId: string) {
    super(`Sessão de login ${sessionId} não encontrada ou já utilizada.`);
  }
}
