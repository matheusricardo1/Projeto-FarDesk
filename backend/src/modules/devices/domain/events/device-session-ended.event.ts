import { DomainEvent } from '@shared/domain/base/domain-event.base';

export class DeviceSessionEndedEvent extends DomainEvent {
  readonly eventName = 'device.session.ended';

  constructor(
    readonly deviceId: string,
    readonly ownerId: string,
  ) {
    super();
  }
}
