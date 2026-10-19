import { EntityNotFoundException } from '@shared/domain/exceptions/domain.exception';

export class IntegrationNotFoundException extends EntityNotFoundException {
  constructor(platform: string) {
    super(`Nenhuma integração com ${platform} conectada nesta conta.`);
  }
}
