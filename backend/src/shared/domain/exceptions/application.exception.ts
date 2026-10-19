/**
 * Falha de orquestração, não de regra de negócio — tipicamente um provedor
 * externo (Google, Tailscale) recusando algo. Fica separada de
 * `DomainException` porque o domínio nunca fala com o mundo externo.
 */
export abstract class ApplicationException extends Error {
  abstract readonly code: string;

  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

export class ExternalProviderException extends ApplicationException {
  readonly code = 'EXTERNAL_PROVIDER_REJECTED';

  constructor(
    readonly provider: string,
    reason: string,
  ) {
    super(`${provider} recusou a operação: ${reason}`);
  }
}
