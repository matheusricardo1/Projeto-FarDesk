import { DomainEvent } from '@shared/domain/base/domain-event.base';

export class DeviceSessionStartedEvent extends DomainEvent {
  readonly eventName = 'device.session.started';

  constructor(
    readonly deviceId: string,
    readonly ownerId: string,
  ) {
    super();
  }
}
