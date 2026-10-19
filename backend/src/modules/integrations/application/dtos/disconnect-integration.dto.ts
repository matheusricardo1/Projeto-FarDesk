import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';

export interface DisconnectIntegrationDto {
  ownerId: string;
  platform: IntegrationPlatform;
}
