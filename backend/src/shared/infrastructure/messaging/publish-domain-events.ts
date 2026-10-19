import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import type { AggregateRoot } from '@shared/domain/base/aggregate-root.base';
import type { EntityId } from '@shared/domain/base/entity.base';

/** Chamado no `save()` de todo repositório, depois de persistir: publica o que o agregado acumulou e limpa. */
export async function publishDomainEvents(
  publisher: DomainEventPublisher,
  aggregate: AggregateRoot<EntityId>,
): Promise<void> {
  if (aggregate.domainEvents.length === 0) return;
  await publisher.publishAll(aggregate.domainEvents);
  aggregate.clearDomainEvents();
}
