import { EndSessionUseCaseImpl } from '@modules/devices/application/use-cases/end-session.use-case.impl';
import { ListDevicesUseCaseImpl } from '@modules/devices/application/use-cases/list-devices.use-case.impl';
import { RegisterDeviceUseCaseImpl } from '@modules/devices/application/use-cases/register-device.use-case.impl';
import { ReportHeartbeatUseCaseImpl } from '@modules/devices/application/use-cases/report-heartbeat.use-case.impl';
import { RequestWakeUseCaseImpl } from '@modules/devices/application/use-cases/request-wake.use-case.impl';
import { StartSessionUseCaseImpl } from '@modules/devices/application/use-cases/start-session.use-case.impl';
import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DeviceNotAvailableException } from '@modules/devices/domain/exceptions/device-not-available.exception';
import { DeviceNotFoundException } from '@modules/devices/domain/exceptions/device-not-found.exception';
import { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

/** Fake sem o Nest em pé. */
class FakeDeviceRepository implements DeviceRepository {
  private readonly devices = new Map<string, Device>();

  add(device: Device): void {
    this.devices.set(device.id.value, device);
  }

  async findById(id: DeviceId): Promise<Device | null> {
    return this.devices.get(id.value) ?? null;
  }

  async findAllByOwner(ownerId: string): Promise<Device[]> {
    return [...this.devices.values()].filter((device) => device.ownerId === ownerId);
  }

  async save(device: Device): Promise<void> {
    this.devices.set(device.id.value, device);
  }
}

const OWNER = 'owner-1';

describe('Casos de uso de dispositivos', () => {
  let repository: FakeDeviceRepository;

  beforeEach(() => {
    repository = new FakeDeviceRepository();
  });

  it('ListDevices só lista dispositivos do dono', async () => {
    repository.add(
      Device.create({ ownerId: OWNER, name: 'PC do Matheus', platform: DevicePlatform.Windows }),
    );
    repository.add(
      Device.create({ ownerId: 'outra-conta', name: 'PC Alheio', platform: DevicePlatform.Windows }),
    );

    const result = await new ListDevicesUseCaseImpl(repository).execute({ ownerId: OWNER });

    expect(result.value).toHaveLength(1);
    expect(result.value[0]?.name).toBe('PC do Matheus');
  });

  it('StartSession falha pra dispositivo de outra conta', async () => {
    const device = Device.create({
      ownerId: 'outra-conta',
      name: 'PC Alheio',
      platform: DevicePlatform.Windows,
    });
    device.recordHeartbeat(new Date());
    repository.add(device);

    const result = await new StartSessionUseCaseImpl(repository).execute({
      deviceId: device.id.value,
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(NotDeviceOwnerException);
  });

  it('StartSession falha pra dispositivo inexistente', async () => {
    const result = await new StartSessionUseCaseImpl(repository).execute({
      deviceId: 'nao-existe',
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(DeviceNotFoundException);
  });

  it('StartSession falha se o dispositivo não está online', async () => {
    const device = Device.create({ ownerId: OWNER, name: 'PC', platform: DevicePlatform.Windows });
    repository.add(device);

    const result = await new StartSessionUseCaseImpl(repository).execute({
      deviceId: device.id.value,
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(DeviceNotAvailableException);
  });

  it('fluxo completo: heartbeat → conectar → desconectar', async () => {
    const device = Device.create({ ownerId: OWNER, name: 'PC', platform: DevicePlatform.Windows });
    repository.add(device);
    const action = { deviceId: device.id.value, ownerId: OWNER };

    const heartbeat = await new ReportHeartbeatUseCaseImpl(repository).execute(action);
    expect(heartbeat.value.device.status).toBe(DeviceStatus.Online);
    expect(heartbeat.value.nextHeartbeatIntervalSeconds).toBe(60);

    const connected = await new StartSessionUseCaseImpl(repository).execute(action);
    expect(connected.value.status).toBe(DeviceStatus.InUse);

    const secondHeartbeat = await new ReportHeartbeatUseCaseImpl(repository).execute(action);
    expect(secondHeartbeat.value.nextHeartbeatIntervalSeconds).toBe(2);

    const disconnected = await new EndSessionUseCaseImpl(repository).execute(action);
    expect(disconnected.value.status).toBe(DeviceStatus.Online);
  });

  it('RequestWake só funciona em dispositivo hibernando, e não muda o status sozinho', async () => {
    repository.add(
      Device.reconstruct({
        id: DeviceId.create('ps5'),
        ownerId: OWNER,
        name: 'PS5',
        platform: DevicePlatform.PS5,
        status: DeviceStatus.Hibernating,
        lastHeartbeatAt: null,
        activeViewerCount: 0,
        hostCredential: null,
      }),
    );

    const result = await new RequestWakeUseCaseImpl(repository).execute({ deviceId: 'ps5', ownerId: OWNER });

    expect(result.value.status).toBe(DeviceStatus.Hibernating);
  });

  it('RegisterDevice cria o dispositivo com o id que o cliente mandou', async () => {
    const result = await new RegisterDeviceUseCaseImpl(repository).execute({
      ownerId: OWNER,
      deviceId: 'local-uuid-1',
      name: 'PC do Matheus',
      platform: DevicePlatform.Windows,
    });

    expect(result.value.id).toBe('local-uuid-1');
    expect(await repository.findById(DeviceId.create('local-uuid-1'))).not.toBeNull();
  });

  it('RegisterDevice é idempotente — chamar de novo não duplica nem falha', async () => {
    const useCase = new RegisterDeviceUseCaseImpl(repository);
    const command = { ownerId: OWNER, deviceId: 'local-uuid-2', name: 'PC', platform: DevicePlatform.Windows };

    await useCase.execute(command);
    const second = await useCase.execute(command);

    expect(second.value.id).toBe('local-uuid-2');
    expect((await repository.findAllByOwner(OWNER)).filter((d) => d.id.value === 'local-uuid-2')).toHaveLength(1);
  });

  it('RegisterDevice reconhece a mesma máquina sob um deviceId local diferente em vez de duplicar', async () => {
    const useCase = new RegisterDeviceUseCaseImpl(repository);
    await useCase.execute({
      ownerId: OWNER,
      deviceId: 'instalacao-dev',
      name: 'DESKTOP-MATHEUS',
      platform: DevicePlatform.Windows,
    });

    const second = await useCase.execute({
      ownerId: OWNER,
      deviceId: 'instalacao-producao',
      name: 'desktop-matheus',
      platform: DevicePlatform.Windows,
    });

    expect(second.value.id).toBe('instalacao-dev');
    expect(await repository.findAllByOwner(OWNER)).toHaveLength(1);
  });

  it('RegisterDevice não mistura máquinas diferentes só por terem a mesma plataforma', async () => {
    const useCase = new RegisterDeviceUseCaseImpl(repository);
    await useCase.execute({ ownerId: OWNER, deviceId: 'pc-1', name: 'PC da Sala', platform: DevicePlatform.Windows });

    await useCase.execute({ ownerId: OWNER, deviceId: 'pc-2', name: 'Notebook', platform: DevicePlatform.Windows });

    expect(await repository.findAllByOwner(OWNER)).toHaveLength(2);
  });

  it('StartSession recusa um "online" guardado cujo heartbeat já é velho demais', async () => {
    const device = Device.reconstruct({
      id: DeviceId.create('stale'),
      ownerId: OWNER,
      name: 'PC',
      platform: DevicePlatform.Windows,
      status: DeviceStatus.Online,
      lastHeartbeatAt: new Date(Date.now() - 10 * 60 * 1000),
      activeViewerCount: 0,
      hostCredential: null,
    });
    repository.add(device);

    const result = await new StartSessionUseCaseImpl(repository).execute({
      deviceId: 'stale',
      ownerId: OWNER,
    });

    expect(result.error).toBeInstanceOf(DeviceNotAvailableException);
  });

  it('RegisterDevice recusa um deviceId que já pertence a outra conta', async () => {
    repository.add(
      Device.create({ id: DeviceId.create('roubado'), ownerId: 'outra-conta', name: 'PC', platform: DevicePlatform.Windows }),
    );

    const result = await new RegisterDeviceUseCaseImpl(repository).execute({
      ownerId: OWNER,
      deviceId: 'roubado',
      name: 'PC',
      platform: DevicePlatform.Windows,
    });

    expect(result.error).toBeInstanceOf(NotDeviceOwnerException);
  });
});
