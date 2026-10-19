import { Inject, Injectable } from '@nestjs/common';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';
import type { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import { LoginSessionPersistenceMapper } from '@modules/auth/infrastructure/persistence/mappers/login-session.persistence.mapper';
import type { LoginSessionRecord } from '@modules/auth/infrastructure/persistence/mappers/login-session.persistence.mapper';

@Injectable()
export class InMemoryLoginSessionRepository implements LoginSessionRepository {
  private readonly records = new Map<string, LoginSessionRecord>();

  constructor(@Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher) {}

  async findById(id: string): Promise<LoginSession | null> {
    const record = this.records.get(id);
    return record ? LoginSessionPersistenceMapper.toDomain(record) : null;
  }

  async save(session: LoginSession): Promise<void> {
    this.records.set(session.id.value, LoginSessionPersistenceMapper.toRecord(session));
    await publishDomainEvents(this.events, session);
  }

  async delete(id: string): Promise<void> {
    this.records.delete(id);
  }
}
