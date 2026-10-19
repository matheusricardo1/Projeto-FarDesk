import { Inject, Injectable } from '@nestjs/common';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';
import type { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import type { AccountRepository } from '@modules/auth/domain/repositories/account.repository';
import { AccountPersistenceMapper } from '@modules/auth/infrastructure/persistence/mappers/account.persistence.mapper';
import type { AccountRecord } from '@modules/auth/infrastructure/persistence/mappers/account.persistence.mapper';

@Injectable()
export class InMemoryAccountRepository implements AccountRepository {
  private readonly records = new Map<string, AccountRecord>();

  constructor(@Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher) {}

  async findById(id: string): Promise<Account | null> {
    const record = this.records.get(id);
    return record ? AccountPersistenceMapper.toDomain(record) : null;
  }

  async findByGoogleSub(googleSub: string): Promise<Account | null> {
    const record = [...this.records.values()].find((candidate) => candidate.googleSub === googleSub);
    return record ? AccountPersistenceMapper.toDomain(record) : null;
  }

  async save(account: Account): Promise<void> {
    this.records.set(account.id.value, AccountPersistenceMapper.toRecord(account));
    await publishDomainEvents(this.events, account);
  }
}
