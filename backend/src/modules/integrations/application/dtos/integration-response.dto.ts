import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import type { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';

/** Nunca contém credencial, nem cifrada. */
export interface IntegrationResponseDto {
  platform: IntegrationPlatform;
  status: IntegrationStatus;
  connectedAt: string | null;
  lastValidatedAt: string | null;
  lastError: string | null;
}
