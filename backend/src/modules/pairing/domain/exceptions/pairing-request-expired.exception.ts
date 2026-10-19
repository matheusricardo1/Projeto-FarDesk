import { BusinessRuleViolationException } from '@shared/domain/exceptions/domain.exception';

export class PairingRequestExpiredException extends BusinessRuleViolationException {
  constructor(requestId: string) {
    super(`Solicitação de pareamento ${requestId} expirou — peça pra conectar de novo.`);
  }
}
