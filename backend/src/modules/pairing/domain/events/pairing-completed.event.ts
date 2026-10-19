import { DomainEvent } from '@shared/domain/base/domain-event.base';

export class PairingCompletedEvent extends DomainEvent {
  readonly eventName = 'pairing.completed';

  constructor(
    readonly requestId: string,
    readonly deviceId: string,
    readonly ownerId: string,
  ) {
    super();
  }
}
