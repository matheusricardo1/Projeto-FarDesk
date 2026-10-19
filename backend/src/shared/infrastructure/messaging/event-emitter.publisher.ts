import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';

import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import type { DomainEvent } from '@shared/domain/base/domain-event.base';

/** Publica em processo via `EventEmitter2`. Trocar por um broker (SQS, Redis Streams) é trocar só esta classe. */
@Injectable()
export class EventEmitterDomainEventPublisher implements DomainEventPublisher {
  constructor(private readonly emitter: EventEmitter2) {}

  async publishAll(events: readonly DomainEvent[]): Promise<void> {
    for (const event of events) {
      await this.emitter.emitAsync(event.eventName, event);
    }
  }
}
