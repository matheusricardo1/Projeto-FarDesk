import type { DomainEvent } from '@shared/domain/base/domain-event.base';

export const DOMAIN_EVENT_PUBLISHER = Symbol('DOMAIN_EVENT_PUBLISHER');

/** Chamado pelos repositórios depois de persistir — nunca pelo caso de uso, pra não publicar algo que não foi salvo. */
export interface DomainEventPublisher {
  publishAll(events: readonly DomainEvent[]): Promise<void>;
}
