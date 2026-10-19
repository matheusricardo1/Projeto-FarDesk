import { AggregateRoot } from '@shared/domain/base/aggregate-root.base';

import { PairingCompletedEvent } from '@modules/pairing/domain/events/pairing-completed.event';
import { PairingRequestedEvent } from '@modules/pairing/domain/events/pairing-requested.event';
import { PairingRequestExpiredException } from '@modules/pairing/domain/exceptions/pairing-request-expired.exception';
import { PairingRequestId } from '@modules/pairing/domain/value-objects/pairing-request-id.vo';
import { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';

/**
 * 30s é generoso o bastante pro agente (que vai pollar a cada ~1s) pegar o
 * PIN, submeter pro Sunshine local e o cliente terminar o handshake HTTPS —
 * tudo isso é só troca de HTTP, não tem por que durar mais que isso.
 */
const PAIRING_REQUEST_TTL_SECONDS = 30;

export interface PairingRequestProps {
  id: PairingRequestId;
  deviceId: string;
  ownerId: string;
  pin: string;
  status: PairingRequestStatus;
  createdAt: Date;
  expiresAt: Date;
  failureReason: string | null;
}

/**
 * Ponte entre o cliente (que gera o PIN e faz o handshake HTTPS direto com o
 * host) e o agente do host (que submete esse mesmo PIN pro Sunshine local,
 * sem humano digitando nada). O backend nunca fala o protocolo Sunshine —
 * só carrega o PIN de um lado pro outro, porque os dois já provaram pertencer
 * à mesma conta (é isso que substitui a confirmação manual na UI do Sunshine).
 */
export class PairingRequest extends AggregateRoot<PairingRequestId> {
  private props: PairingRequestProps;

  private constructor(props: PairingRequestProps) {
    super(props.id);
    this.props = props;
  }

  static request(props: { deviceId: string; ownerId: string; pin: string; now: Date }): PairingRequest {
    const request = new PairingRequest({
      id: PairingRequestId.create(),
      deviceId: props.deviceId,
      ownerId: props.ownerId,
      pin: props.pin,
      status: PairingRequestStatus.Pending,
      createdAt: props.now,
      expiresAt: new Date(props.now.getTime() + PAIRING_REQUEST_TTL_SECONDS * 1000),
      failureReason: null,
    });
    request.addDomainEvent(
      new PairingRequestedEvent(request.id.value, props.deviceId, props.ownerId, props.pin),
    );
    return request;
  }

  static reconstruct(props: PairingRequestProps): PairingRequest {
    return new PairingRequest(props);
  }

  get deviceId(): string {
    return this.props.deviceId;
  }

  get ownerId(): string {
    return this.props.ownerId;
  }

  get pin(): string {
    return this.props.pin;
  }

  get status(): PairingRequestStatus {
    return this.props.status;
  }

  get expiresAt(): Date {
    return this.props.expiresAt;
  }

  get failureReason(): string | null {
    return this.props.failureReason;
  }

  isExpired(now: Date): boolean {
    return now.getTime() > this.props.expiresAt.getTime();
  }

  isActive(now: Date): boolean {
    const activeStatus =
      this.props.status === PairingRequestStatus.Pending ||
      this.props.status === PairingRequestStatus.Delivered;
    return activeStatus && !this.isExpired(now);
  }

  /** O agente confirma que já submeteu o PIN pro Sunshine local. */
  acknowledge(now: Date): void {
    this.assertActive(now);
    this.props.status = PairingRequestStatus.Delivered;
  }

  /** O cliente confirma que o handshake HTTPS fechou — fim feliz. */
  complete(now: Date): void {
    this.assertActive(now);
    this.props.status = PairingRequestStatus.Completed;
    this.addDomainEvent(new PairingCompletedEvent(this.id.value, this.props.deviceId, this.props.ownerId));
  }

  fail(reason: string): void {
    this.props.status = PairingRequestStatus.Failed;
    this.props.failureReason = reason;
  }

  /** Housekeeping: marca como expirada em vez de deixar `Pending` pra sempre quando ninguém nunca pegou o PIN. */
  expire(): void {
    this.props.status = PairingRequestStatus.Expired;
  }

  private assertActive(now: Date): void {
    if (!this.isActive(now)) {
      throw new PairingRequestExpiredException(this.id.value);
    }
  }

  toSnapshot(): Readonly<PairingRequestProps> {
    return { ...this.props };
  }
}
