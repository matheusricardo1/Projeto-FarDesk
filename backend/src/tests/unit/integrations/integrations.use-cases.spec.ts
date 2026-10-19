import type { CredentialCipher } from '@modules/integrations/application/ports/out/credential-cipher.port';
import type {
  TailscaleAuthKeyOptions,
  TailscaleDevice,
  TailscaleGateway,
  TailscaleOAuthCredential,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';
import { ConnectTailscaleIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/connect-tailscale-integration.use-case.impl';
import { DisconnectIntegrationUseCaseImpl } from '@modules/integrations/application/use-cases/disconnect-integration.use-case.impl';
import { ListTailscaleDevicesUseCaseImpl } from '@modules/integrations/application/use-cases/list-tailscale-devices.use-case.impl';
import type { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import { IntegrationNotFoundException } from '@modules/integrations/domain/exceptions/integration-not-found.exception';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { EncryptedCredential } from '@modules/integrations/domain/value-objects/encrypted-credential.vo';
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
    private readonly validCredential: TailscaleOAuthCredential,
    private readonly devices: TailscaleDevice[] = [],
  ) {}

  async exchangeForAccessToken(credential: TailscaleOAuthCredential): Promise<Result<string, Error>> {
    const valid =
      credential.clientId === this.validCredential.clientId &&
      credential.clientSecret === this.validCredential.clientSecret;
    return valid ? Result.ok('fake-access-token') : Result.err(new Error('HTTP 401'));
  }

  async listDevices(): Promise<Result<TailscaleDevice[], Error>> {
    return Result.ok(this.devices);
  }

  async createAuthKey(
    _accessToken: string,
    _options: TailscaleAuthKeyOptions,
  ): Promise<Result<string, Error>> {
    return Result.ok('tskey-auth-fake');
  }
}

const OWNER = 'owner-1';
const VALID_CREDENTIAL: TailscaleOAuthCredential = { clientId: 'client-abc', clientSecret: 'secret-xyz' };

describe('Casos de uso de integrações', () => {
  let repository: FakeIntegrationRepository;
  let cipher: FakePlaintextCipher;

  beforeEach(() => {
    repository = new FakeIntegrationRepository();
    cipher = new FakePlaintextCipher();
  });

  function connect(gateway = new FakeTailscaleGateway(VALID_CREDENTIAL)) {
    return new ConnectTailscaleIntegrationUseCaseImpl(repository, gateway, cipher);
  }

  it('Connect valida a credencial antes de persistir', async () => {
    const result = await connect().execute({ ownerId: OWNER, ...VALID_CREDENTIAL });

    expect(result.value.status).toBe(IntegrationStatus.Connected);
    expect(await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale)).not.toBeNull();
  });

  it('Connect não persiste nada se a credencial for inválida', async () => {
    const result = await connect().execute({ ownerId: OWNER, clientId: 'errado', clientSecret: 'errado' });

    expect(result.error).toBeInstanceOf(ExternalProviderException);
    expect(await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale)).toBeNull();
  });

  it('a resposta nunca carrega a credencial', async () => {
    const result = await connect().execute({ ownerId: OWNER, ...VALID_CREDENTIAL });

    expect(result.value).not.toHaveProperty('credential');
    expect(JSON.stringify(result.value)).not.toContain(VALID_CREDENTIAL.clientSecret);
  });

  it('a credencial persistida passa sempre pelo cipher', async () => {
    await connect().execute({ ownerId: OWNER, ...VALID_CREDENTIAL });

    const saved = await repository.findByOwnerAndPlatform(OWNER, IntegrationPlatform.Tailscale);
    expect(saved?.credential).toEqual(
      expect.objectContaining({ ciphertext: JSON.stringify(VALID_CREDENTIAL) }),
    );
  });

  it('Disconnect descarta a credencial guardada', async () => {
    await connect().execute({ ownerId: OWNER, ...VALID_CREDENTIAL });

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

  it('ListTailscaleDevices resolve os devices da tailnet com a credencial guardada', async () => {
    const devices: TailscaleDevice[] = [
      { id: '1', name: 'pc-matheus', hostname: 'pc-matheus', addresses: ['100.64.0.1'], online: true },
    ];
    const gateway = new FakeTailscaleGateway(VALID_CREDENTIAL, devices);
    await connect(gateway).execute({ ownerId: OWNER, ...VALID_CREDENTIAL });

    const result = await new ListTailscaleDevicesUseCaseImpl(repository, gateway, cipher).execute({
      ownerId: OWNER,
    });

    expect(result.value).toEqual(devices);
  });

  it('ListTailscaleDevices falha se não houver integração', async () => {
    const gateway = new FakeTailscaleGateway(VALID_CREDENTIAL);

    const result = await new ListTailscaleDevicesUseCaseImpl(repository, gateway, cipher).execute({
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(IntegrationNotFoundException);
  });
});
