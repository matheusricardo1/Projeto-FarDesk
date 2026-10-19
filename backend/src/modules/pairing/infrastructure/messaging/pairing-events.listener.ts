import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';

import type { PairingCompletedEvent } from '@modules/pairing/domain/events/pairing-completed.event';
import type { PairingRequestedEvent } from '@modules/pairing/domain/events/pairing-requested.event';

/**
 * Hoje só loga. É aqui que entra o push de verdade pro agente (WebSocket/SSE)
 * quando ele existir, no lugar do agente ficar perguntando via polling —
 * `pairing.requested` já carrega tudo que esse push precisaria (deviceId, PIN).
 */
@Injectable()
export class PairingEventsListener {
  private readonly logger = new Logger(PairingEventsListener.name);

  @OnEvent('pairing.requested')
  onPairingRequested(event: PairingRequestedEvent): void {
    this.logger.log(
      `Pareamento solicitado: device=${event.deviceId} owner=${event.ownerId} request=${event.requestId}`,
    );
  }

  @OnEvent('pairing.completed')
  onPairingCompleted(event: PairingCompletedEvent): void {
    this.logger.log(
      `Pareamento concluído: device=${event.deviceId} owner=${event.ownerId} request=${event.requestId}`,
    );
  }
}
