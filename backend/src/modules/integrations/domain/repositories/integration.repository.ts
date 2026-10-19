import type { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';

export const INTEGRATION_REPOSITORY = Symbol('INTEGRATION_REPOSITORY');

export interface IntegrationRepository {
  findByOwnerAndPlatform(ownerId: string, platform: IntegrationPlatform): Promise<Integration | null>;
  findAllByOwner(ownerId: string): Promise<Integration[]>;
  save(integration: Integration): Promise<void>;
}
