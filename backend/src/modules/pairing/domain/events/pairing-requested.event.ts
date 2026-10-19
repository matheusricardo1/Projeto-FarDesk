import { DomainEvent } from '@shared/domain/base/domain-event.base';

/**
 * O gatilho que, no futuro, troca o polling do agente por um push de verdade
 * (WebSocket/SSE) — o agente ouviria isso direto em vez de bater na API a
 * cada segundo perguntando "tem pareamento pendente?".
 */
export class PairingRequestedEvent extends DomainEvent {
  readonly eventName = 'pairing.requested';

  constructor(
    readonly requestId: string,
    readonly deviceId: string,
    readonly ownerId: string,
    readonly pin: string,
  ) {
    super();
  }
}
