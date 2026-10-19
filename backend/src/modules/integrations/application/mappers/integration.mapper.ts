import type { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';

export class IntegrationMapper {
  static toResponse(integration: Integration): IntegrationResponseDto {
    return {
      platform: integration.platform,
      status: integration.status,
      connectedAt: integration.connectedAt?.toISOString() ?? null,
      lastValidatedAt: integration.lastValidatedAt?.toISOString() ?? null,
      lastError: integration.lastError,
    };
  }
}
