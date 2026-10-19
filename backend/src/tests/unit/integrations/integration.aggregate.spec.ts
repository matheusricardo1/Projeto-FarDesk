import { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';

const CREDENTIAL = { ciphertext: 'c', iv: 'i', authTag: 't' };

function connected(): Integration {
  return Integration.connect({
    ownerId: 'owner-1',
    platform: IntegrationPlatform.Tailscale,
    credential: CREDENTIAL,
    now: new Date(),
  });
}

describe('Integration', () => {
  it('nasce conectada e com a credencial guardada', () => {
    const integration = connected();

    expect(integration.status).toBe(IntegrationStatus.Connected);
    expect(integration.credential).toEqual(CREDENTIAL);
  });

  it('disconnect descarta a credencial, não só marca status', () => {
    const integration = connected();

    integration.disconnect();

    expect(integration.status).toBe(IntegrationStatus.Disconnected);
    expect(integration.credential).toBeNull();
  });

  it('markError registra o motivo sem descartar a credencial', () => {
    const integration = connected();

    integration.markError('OAuth client revogado');

    expect(integration.status).toBe(IntegrationStatus.Error);
    expect(integration.lastError).toBe('OAuth client revogado');
    expect(integration.credential).toEqual(CREDENTIAL);
  });

  it('rotateCredential reconecta e limpa o erro anterior', () => {
    const integration = connected();
    integration.markError('falhou');

    const newCredential = { ciphertext: 'c2', iv: 'i2', authTag: 't2' };
    integration.rotateCredential(newCredential, new Date());

    expect(integration.status).toBe(IntegrationStatus.Connected);
    expect(integration.credential).toEqual(newCredential);
    expect(integration.lastError).toBeNull();
  });
});
