import { Inject, Injectable } from '@nestjs/common';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';
import type { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import { IntegrationPersistenceMapper } from '@modules/integrations/infrastructure/persistence/mappers/integration.persistence.mapper';
import type { IntegrationRecord } from '@modules/integrations/infrastructure/persistence/mappers/integration.persistence.mapper';

/** Em memória — em serverless nada sobrevive entre invocações. Troca por Prisma sobre o mesmo mapper. */
@Injectable()
export class InMemoryIntegrationRepository implements IntegrationRepository {
  private readonly records = new Map<string, IntegrationRecord>();

  constructor(@Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher) {}

  async findByOwnerAndPlatform(ownerId: string, platform: IntegrationPlatform): Promise<Integration | null> {
    const record = this.records.get(this.key(ownerId, platform));
    return record ? IntegrationPersistenceMapper.toDomain(record) : null;
  }

  async findAllByOwner(ownerId: string): Promise<Integration[]> {
    return [...this.records.values()]
      .filter((record) => record.ownerId === ownerId)
      .map((record) => IntegrationPersistenceMapper.toDomain(record));
  }

  async save(integration: Integration): Promise<void> {
    this.records.set(
      this.key(integration.ownerId, integration.platform),
      IntegrationPersistenceMapper.toRecord(integration),
    );
    await publishDomainEvents(this.events, integration);
  }

  private key(ownerId: string, platform: IntegrationPlatform): string {
    return `${ownerId}:${platform}`;
  }
}
