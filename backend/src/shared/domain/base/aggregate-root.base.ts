import type { DomainEvent } from '@shared/domain/base/domain-event.base';
import { Entity } from '@shared/domain/base/entity.base';
import type { EntityId } from '@shared/domain/base/entity.base';

/**
 * Raiz de um agregado — única porta de entrada pra mudar estado dentro dele.
 * Acumula os eventos que suas transições disparam; quem publica é a
 * infraestrutura, depois de persistir com sucesso.
 */
export abstract class AggregateRoot<Id extends EntityId> extends Entity<Id> {
  private readonly _domainEvents: DomainEvent[] = [];

  get domainEvents(): ReadonlyArray<DomainEvent> {
    return this._domainEvents;
  }

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  clearDomainEvents(): void {
    this._domainEvents.length = 0;
  }
}
