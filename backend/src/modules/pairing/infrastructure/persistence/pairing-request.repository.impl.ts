import { Inject, Injectable } from '@nestjs/common';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';

import type { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';
import { PairingRequestPersistenceMapper } from '@modules/pairing/infrastructure/persistence/mappers/pairing-request.persistence.mapper';
import type { PairingRequestRecord } from '@modules/pairing/infrastructure/persistence/mappers/pairing-request.persistence.mapper';

/** Em memória — uma solicitação de pareamento vive 30s, nunca precisou sobreviver a um restart. */
@Injectable()
export class InMemoryPairingRequestRepository implements PairingRequestRepository {
  private readonly records = new Map<string, PairingRequestRecord>();

  constructor(@Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher) {}

  async findById(id: string): Promise<PairingRequest | null> {
    const record = this.records.get(id);
    return record ? PairingRequestPersistenceMapper.toDomain(record) : null;
  }

  async findActiveByDevice(deviceId: string): Promise<PairingRequest | null> {
    const active = [...this.records.values()]
      .filter(
        (record) =>
          record.deviceId === deviceId &&
          (record.status === PairingRequestStatus.Pending ||
            record.status === PairingRequestStatus.Delivered),
      )
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));

    const record = active[0];
    return record ? PairingRequestPersistenceMapper.toDomain(record) : null;
  }

  async save(request: PairingRequest): Promise<void> {
    this.records.set(request.id.value, PairingRequestPersistenceMapper.toRecord(request));
    await publishDomainEvents(this.events, request);
  }
}
