/**
 * Violação de regra de negócio. Cada bounded context estende uma destas
 * três categorias; a camada HTTP mapeia a categoria pro status certo
 * (ver `AllExceptionsFilter`) sem conhecer cada subtipo.
 */
export abstract class DomainException extends Error {
  abstract readonly code: string;

  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

export class EntityNotFoundException extends DomainException {
  readonly code = 'NOT_FOUND';
  constructor(message: string) {
    super(message);
  }
}

export class BusinessRuleViolationException extends DomainException {
  readonly code = 'CONFLICT';
  constructor(message: string) {
    super(message);
  }
}

export class InvalidValueException extends DomainException {
  readonly code = 'VALIDATION_ERROR';
  constructor(message: string) {
    super(message);
  }
}
