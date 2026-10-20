import type { CredentialCipher } from '@shared/application/ports/credential-cipher.port';
import type {
  TailscaleAuthKeyOptions,
  TailscaleDevice,
  TailscaleGateway,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import { ConnectTailscaleIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/connect-tailscale-integration.use-case.impl';
import { DisconnectIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/disconnect-integration.use-case.impl';
import { ListTailscaleDevicesUseCaseImpl } from '@modules/integrations/application/use-cases/list-tailscale-devices.use-case.impl';
import type { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { EncryptedCredential } from '@shared/domain/types/encrypted-credential.vo';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';
import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';

class FakeIntegrationRepository implements IntegrationRepository {
  private readonly integrations = new Map<string, Integration>();

  async findByOwnerAndPlatform(ownerId: string, platform: IntegrationPlatform): Promise<Integration | null> {
    return this.integrations.get(`${ownerId}:${platform}`) ?? null;
  }

  async findAllByOwner(ownerId: string): Promise<Integration[]> {
    return [...this.integrations.values()].filter((integration) => integration.ownerId === ownerId);
  }

  async save(integration: Integration): Promise<void> {
    this.integrations.set(`${integration.ownerId}:${integration.platform}`, integration);
  }
}

/** Não cifra de verdade — só preserva o shape de `EncryptedCredential`. */
class FakePlaintextCipher implements CredentialCipher {
  encrypt(plaintext: string): EncryptedCredential {
    return { ciphertext: plaintext, iv: 'fake-iv', authTag: 'fake-tag' };
  }

  decrypt(payload: EncryptedCredential): string {
    return payload.ciphertext;
  }
}

class FakeTailscaleGateway implements TailscaleGateway {
  constructor(
    private readonly validToken: string,
    private readonly devices: TailscaleDevice[] = [],
  ) {}

  async validateAccessToken(apiAccessToken: string): Promise<Result<void, Error>> {
    return apiAccessToken === this.validToken ? Result.ok(undefined) : Result.err(new Error('HTTP 401'));
  }

  async listDevices(apiAccessToken: string): Promise<Result<TailscaleDevice[], Error>> {
    if (apiAccessToken !== this.validToken) return Result.err(new Error('HTTP 401'));
    return Result.ok(this.devices);
  }

  async createAuthKey(
    _apiAccessToken: string,
    _options: TailscaleAuthKeyOptions,
  ): Promise<Result<string, Error>> {
    return Result.ok('tskey-auth-fake');
  }
}

const OWNER = 'owner-1';
const VALID_TOKEN = 'tskey-api-valid';

describe('Casos de uso de integrações', () => {
  let repository: FakeIntegrationRepository;
  let cipher: FakePlaintextCipher;

  beforeEach(() => {
    repository = new FakeIntegrationRepository();
    cipher = new FakePlaintextCipher();
  });

  function connect(gateway = new FakeTailscaleGateway(VALID_TOKEN)) {
    return new ConnectTailscaleIntegrationUseCaseImpl(repository, gateway, cipher);
  }

  it('Connect valida o token antes de persistir', async () => {
    const result = await connect().execute({ ownerId: OWNER, apiAccessToken: VALID_TOKEN });

    expect(result.value.status).toBe(IntegrationStatus.Connected);
    expect(await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale)).not.toBeNull();
  });

  it('Connect não persiste nada se o token for inválido', async () => {
    const result = await connect().execute({ ownerId: OWNER, apiAccessToken: 'errado' });

    expect(result.error).toBeInstanceOf(ExternalProviderException);
    expect(await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale)).toBeNull();
  });

  it('a resposta nunca carrega a credencial', async () => {
    const result = await connect().execute({ ownerId: OWNER, apiAccessToken: VALID_TOKEN });

    expect(result.value).not.toHaveProperty('credential');
    expect(JSON.stringify(result.value)).not.toContain(VALID_TOKEN);
  });

  it('a credencial persistida passa sempre pelo cipher', async () => {
    await connect().execute({ ownerId: OWNER, apiAccessToken: VALID_TOKEN });

    const saved = await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale);
    expect(saved?.credential).toEqual(
      expect.objectContaining({ ciphertext: JSON.stringify({ apiAccessToken: VALID_TOKEN }) }),
    );
  });

  it('Disconnect descarta a credencial guardada', async () => {
    await connect().execute({ ownerId: OWNER, apiAccessToken: VALID_TOKEN });

    const result = await new DisconnectIntegrationUseCaseImpl(repository).execute({
      ownerId: OWNER,
      platform: IntegrationPlatform.Tailscale,
    });

    expect(result.value.status).toBe(IntegrationStatus.Disconnected);
    expect(
      (await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale))?.credential,
    ).toBeNull();
  });

  it('Disconnect falha se não houver integração', async () => {
    const result = await new DisconnectIntegrationUseCaseImpl(repository).execute({
      ownerId: OWNER,
      platform: IntegrationPlatform.Tailscale,
    });

    expect(result.error).toBeInstanceOf(IntegrationNotFoundException);
  });

  it('ListTailscaleDevices resolve os devices da tailnet com o token guardado', async () => {
    const devices: TailscaleDevice[] = [
      { id: '1', name: 'pc-matheus', hostname: 'pc-matheus', addresses: ['100.64.0.1'], online: true },
    ];
    const gateway = new FakeTailscaleGateway(VALID_TOKEN, devices);
    await connect(gateway).execute({ ownerId: OWNER, apiAccessToken: VALID_TOKEN });

    const result = await new ListTailscaleDevicesUseCaseImpl(repository, gateway, cipher).execute({
      ownerId: OWNER,
    });

    expect(result.value).toEqual(devices);
  });

  it('ListTailscaleDevices falha se não houver integração', async () => {
    const gateway = new FakeTailscaleGateway(VALID_TOKEN);

    const result = await new ListTailscaleDevicesUseCaseImpl(repository, gateway, cipher).execute({
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(IntegrationNotFoundException);
  });
});
