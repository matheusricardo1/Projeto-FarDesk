import { AggregateRoot } from '@shared/domain/base/aggregate-root.base';
import { IntegrationConnectedEvent } from '@modules/integrations/domain/events/integration-connected.event';
import { IntegrationDisconnectedEvent } from '@modules/integrations/domain/events/integration-disconnected.event';
import type { EncryptedCredential } from '@shared/domain/types/encrypted-credential.vo';
import { IntegrationId } from '@modules/integrations/domain/value-objects/integration-id.vo';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';

export interface IntegrationProps {
  id: IntegrationId;
  ownerId: string;
  platform: IntegrationPlatform;
  status: IntegrationStatus;
  credential: EncryptedCredential | null;
  connectedAt: Date | null;
  lastValidatedAt: Date | null;
  lastError: string | null;
}

/**
 * Integração de uma conta com um provedor externo. Único dono da credencial
 * cifrada — o mapper de resposta nunca a expõe.
 */
export class Integration extends AggregateRoot<IntegrationId> {
  private props: IntegrationProps;

  private constructor(props: IntegrationProps) {
    super(props.id);
    this.props = props;
  }

  /** A credencial já foi validada contra o provedor antes de chegar aqui. */
  static connect(props: {
    ownerId: string;
    platform: IntegrationPlatform;
    credential: EncryptedCredential;
    now: Date;
    id?: IntegrationId;
  }): Integration {
    const integration = new Integration({
      id: props.id ?? IntegrationId.create(),
      ownerId: props.ownerId,
      platform: props.platform,
      status: IntegrationStatus.Connected,
      credential: props.credential,
      connectedAt: props.now,
      lastValidatedAt: props.now,
      lastError: null,
    });
    integration.addDomainEvent(new IntegrationConnectedEvent(props.ownerId, props.platform));
    return integration;
  }

  static reconstruct(props: IntegrationProps): Integration {
    return new Integration(props);
  }

  get ownerId(): string {
    return this.props.ownerId;
  }

  get platform(): IntegrationPlatform {
    return this.props.platform;
  }

  get status(): IntegrationStatus {
    return this.props.status;
  }

  get credential(): EncryptedCredential | null {
    return this.props.credential;
  }

  get connectedAt(): Date | null {
    return this.props.connectedAt;
  }

  get lastValidatedAt(): Date | null {
    return this.props.lastValidatedAt;
  }

  get lastError(): string | null {
    return this.props.lastError;
  }

  rotateCredential(credential: EncryptedCredential, now: Date): void {
    this.props.credential = credential;
    this.props.status = IntegrationStatus.Connected;
    this.props.connectedAt ??= now;
    this.props.lastValidatedAt = now;
    this.props.lastError = null;
    this.addDomainEvent(new IntegrationConnectedEvent(this.props.ownerId, this.props.platform));
  }

  markValidated(now: Date): void {
    this.props.status = IntegrationStatus.Connected;
    this.props.lastValidatedAt = now;
    this.props.lastError = null;
  }

  markError(message: string): void {
    this.props.status = IntegrationStatus.Error;
    this.props.lastError = message;
  }

  /** Descarta a credencial — nada fica guardado que não precise mais existir. */
  disconnect(): void {
    this.props.status = IntegrationStatus.Disconnected;
    this.props.credential = null;
    this.props.lastError = null;
    this.addDomainEvent(new IntegrationDisconnectedEvent(this.props.ownerId, this.props.platform));
  }

  toSnapshot(): Readonly<IntegrationProps> {
    return { ...this.props };
  }
}
