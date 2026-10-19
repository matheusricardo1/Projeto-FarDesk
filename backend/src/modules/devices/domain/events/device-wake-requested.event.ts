import { DomainEvent } from '@shared/domain/base/domain-event.base';

/** Quem reage a isto é o agente do host (Wake-on-LAN), não outro caso de uso. */
export class DeviceWakeRequestedEvent extends DomainEvent {
  readonly eventName = 'device.wake.requested';

  constructor(
    readonly deviceId: string,
    readonly ownerId: string,
  ) {
    super();
  }
}
