/**
 * Algo que já aconteceu no domínio. `eventName` é o canal usado pelo
 * publisher — convenção `<contexto>.<fato>` (ex: `device.session.started`).
 */
export abstract class DomainEvent {
  abstract readonly eventName: string;
  readonly occurredAt: Date = new Date();
}
