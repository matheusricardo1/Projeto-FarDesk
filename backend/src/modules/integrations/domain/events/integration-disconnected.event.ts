import { DomainEvent } from '@shared/domain/base/domain-event.base';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';

export class IntegrationDisconnectedEvent extends DomainEvent {
  readonly eventName = 'integration.disconnected';

  constructor(
    readonly ownerId: string,
    readonly platform: IntegrationPlatform,
  ) {
    super();
  }
}
