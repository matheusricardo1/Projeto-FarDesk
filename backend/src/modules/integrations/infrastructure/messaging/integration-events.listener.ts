import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';

import type { IntegrationConnectedEvent } from '@modules/integrations/domain/events/integration-connected.event';
import type { IntegrationDisconnectedEvent } from '@modules/integrations/domain/events/integration-disconnected.event';

@Injectable()
export class IntegrationEventsListener {
  private readonly logger = new Logger(IntegrationEventsListener.name);

  @OnEvent('integration.connected')
  onConnected(event: IntegrationConnectedEvent): void {
    this.logger.log(`Integração conectada: owner=${event.ownerId} platform=${event.platform}`);
  }

  @OnEvent('integration.disconnected')
  onDisconnected(event: IntegrationDisconnectedEvent): void {
    this.logger.log(`Integração desconectada: owner=${event.ownerId} platform=${event.platform}`);
  }
}
