import { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import type { EncryptedCredential } from '@modules/integrations/domain/value-objects/encrypted-credential.vo';
import { IntegrationId } from '@modules/integrations/domain/value-objects/integration-id.vo';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import type { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';

/** A credencial é gravada já cifrada — o repositório nunca vê o segredo em claro. */
export interface IntegrationRecord {
  id: string;
  ownerId: string;
  platform: IntegrationPlatform;
  status: IntegrationStatus;
  credential: EncryptedCredential | null;
  connectedAt: string | null;
  lastValidatedAt: string | null;
  lastError: string | null;
}

export class IntegrationPersistenceMapper {
  static toRecord(integration: Integration): IntegrationRecord {
    const snapshot = integration.toSnapshot();
    return {
      id: snapshot.id.value,
      ownerId: snapshot.ownerId,
      platform: snapshot.platform,
      status: snapshot.status,
      credential: snapshot.credential ? { ...snapshot.credential } : null,
      connectedAt: snapshot.connectedAt?.toISOString() ?? null,
      lastValidatedAt: snapshot.lastValidatedAt?.toISOString() ?? null,
      lastError: snapshot.lastError,
    };
  }

  static toDomain(record: IntegrationRecord): Integration {
    return Integration.reconstruct({
      id: IntegrationId.create(record.id),
      ownerId: record.ownerId,
      platform: record.platform,
      status: record.status,
      credential: record.credential ? { ...record.credential } : null,
      connectedAt: record.connectedAt ? new Date(record.connectedAt) : null,
      lastValidatedAt: record.lastValidatedAt ? new Date(record.lastValidatedAt) : null,
      lastError: record.lastError,
    });
  }
}
