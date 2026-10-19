import { EntityNotFoundException } from '@shared/domain/exceptions/domain.exception';

export class PairingRequestNotFoundException extends EntityNotFoundException {
  constructor(requestId: string) {
    super(`Solicitação de pareamento ${requestId} não encontrada.`);
  }
}
