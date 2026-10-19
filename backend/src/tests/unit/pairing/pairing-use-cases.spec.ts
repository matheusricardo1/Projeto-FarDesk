import { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import { DeviceNotAccessibleException } from '@modules/pairing/domain/exceptions/device-not-accessible.exception';
import { PairingRequestNotFoundException } from '@modules/pairing/domain/exceptions/pairing-request-not-found.exception';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';
import { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';
import type { DeviceLookupGateway } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import { AckPairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/ack-pairing-request.use-case.impl';
import { CompletePairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/complete-pairing-request.use-case.impl';
import { CreatePairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/create-pairing-request.use-case.impl';
import { GetPendingPairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/get-pending-pairing-request.use-case.impl';

/** Fake sem o Nest em pé. */
class FakePairingRequestRepository implements PairingRequestRepository {
  private readonly requests = new Map<string, PairingRequest>();

  async findById(id: string): Promise<PairingRequest | null> {
    return this.requests.get(id) ?? null;
  }

  async findActiveByDevice(deviceId: string): Promise<PairingRequest | null> {
    const active = [...this.requests.values()]
      .filter(
        (request) =>
          request.deviceId === deviceId &&
          (request.status === PairingRequestStatus.Pending ||
            request.status === PairingRequestStatus.Delivered),
      )
      .sort((a, b) => b.toSnapshot().createdAt.getTime() - a.toSnapshot().createdAt.getTime());
    return active[0] ?? null;
  }

  async save(request: PairingRequest): Promise<void> {
    this.requests.set(request.id.value, request);
  }
}

class FakeDeviceLookupGateway implements DeviceLookupGateway {
  constructor(private readonly ownedDeviceIds: Set<string>) {}

  async isOwnedByAccount(deviceId: string): Promise<boolean> {
    return this.ownedDeviceIds.has(deviceId);
  }
}

const OWNER = 'owner-1';
const DEVICE = 'device-1';

describe('Casos de uso de pairing', () => {
  let repository: FakePairingRequestRepository;
  let devices: FakeDeviceLookupGateway;

  beforeEach(() => {
    repository = new FakePairingRequestRepository();
    devices = new FakeDeviceLookupGateway(new Set([DEVICE]));
  });

  it('Create falha se o dispositivo não é da conta', async () => {
    const result = await new CreatePairingRequestUseCaseImpl(
      repository,
      new FakeDeviceLookupGateway(new Set()),
    ).execute({
      deviceId: DEVICE,
      ownerId: OWNER,
      pin: '1234',
    });

    expect(result.error).toBeInstanceOf(DeviceNotAccessibleException);
  });

  it('fluxo completo: create → pending (agente vê) → ack → complete', async () => {
    const create = new CreatePairingRequestUseCaseImpl(repository, devices);
    const getPending = new GetPendingPairingRequestUseCaseImpl(repository, devices);
    const ack = new AckPairingRequestUseCaseImpl(repository);
    const complete = new CompletePairingRequestUseCaseImpl(repository);

    const created = await create.execute({ deviceId: DEVICE, ownerId: OWNER, pin: '1234' });
    expect(created.isOk).toBe(true);
    expect(created.value.pin).toBe('1234');

    const pending = await getPending.execute({ deviceId: DEVICE, ownerId: OWNER });
    expect(pending.value?.id).toBe(created.value.id);
    expect(pending.value?.status).toBe(PairingRequestStatus.Pending);

    const acked = await ack.execute({ deviceId: DEVICE, requestId: created.value.id, ownerId: OWNER });
    expect(acked.value.status).toBe(PairingRequestStatus.Delivered);

    const completed = await complete.execute({
      deviceId: DEVICE,
      requestId: created.value.id,
      ownerId: OWNER,
    });
    expect(completed.value.status).toBe(PairingRequestStatus.Completed);

    // Já concluída — não deve mais aparecer como pendente pro agente.
    const afterComplete = await getPending.execute({ deviceId: DEVICE, ownerId: OWNER });
    expect(afterComplete.value).toBeNull();
  });

  it('GetPending não devolve a solicitação de outro dispositivo', async () => {
    const create = new CreatePairingRequestUseCaseImpl(
      repository,
      new FakeDeviceLookupGateway(new Set([DEVICE, 'device-2'])),
    );
    await create.execute({ deviceId: DEVICE, ownerId: OWNER, pin: '1234' });

    const getPending = new GetPendingPairingRequestUseCaseImpl(
      repository,
      new FakeDeviceLookupGateway(new Set([DEVICE, 'device-2'])),
    );
    const result = await getPending.execute({ deviceId: 'device-2', ownerId: OWNER });

    expect(result.value).toBeNull();
  });

  it('Ack de uma solicitação inexistente retorna PairingRequestNotFoundException', async () => {
    const ack = new AckPairingRequestUseCaseImpl(repository);

    const result = await ack.execute({ deviceId: DEVICE, requestId: 'nao-existe', ownerId: OWNER });

    expect(result.error).toBeInstanceOf(PairingRequestNotFoundException);
  });

  it('Ack de uma solicitação de outra conta também retorna NotFound — não revela que ela existe', async () => {
    const create = new CreatePairingRequestUseCaseImpl(repository, devices);
    const created = await create.execute({ deviceId: DEVICE, ownerId: OWNER, pin: '1234' });

    const ack = new AckPairingRequestUseCaseImpl(repository);
    const result = await ack.execute({
      deviceId: DEVICE,
      requestId: created.value.id,
      ownerId: 'outra-conta',
    });

    expect(result.error).toBeInstanceOf(PairingRequestNotFoundException);
  });

  it('GetPending expira sozinho uma solicitação vencida', async () => {
    const create = new CreatePairingRequestUseCaseImpl(repository, devices);
    const created = await create.execute({ deviceId: DEVICE, ownerId: OWNER, pin: '1234' });

    // Simula o relógio avançando além do TTL manipulando o registro salvo diretamente.
    const stored = await repository.findById(created.value.id);
    expect(stored).not.toBeNull();
    const expiredSnapshot = stored!.toSnapshot();
    const expired = PairingRequest.reconstruct({
      ...expiredSnapshot,
      expiresAt: new Date(Date.now() - 1_000),
    });
    await repository.save(expired);

    const getPending = new GetPendingPairingRequestUseCaseImpl(repository, devices);
    const result = await getPending.execute({ deviceId: DEVICE, ownerId: OWNER });

    expect(result.value).toBeNull();
  });
});
