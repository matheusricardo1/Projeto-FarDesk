import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import { DeviceNotAvailableException } from '@modules/devices/domain/exceptions/device-not-available.exception';
import { DeviceNotHibernatingException } from '@modules/devices/domain/exceptions/device-not-hibernating.exception';
import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

function offlineDevice(): Device {
  return Device.create({ ownerId: 'owner-1', name: 'PC', platform: DevicePlatform.Windows });
}

function onlineDevice(): Device {
  const device = offlineDevice();
  device.recordHeartbeat(new Date());
  return device;
}

describe('Device', () => {
  it('nasce offline', () => {
    expect(offlineDevice().status).toBe(DeviceStatus.Offline);
  });

  it('fica online ao receber o primeiro heartbeat', () => {
    expect(onlineDevice().status).toBe(DeviceStatus.Online);
  });

  it('heartbeat sozinho não altera quem já está online', () => {
    const device = onlineDevice();
    device.recordHeartbeat(new Date());
    expect(device.status).toBe(DeviceStatus.Online);
  });

  it('iniciar sessão num dispositivo online marca InUse e soma um espectador', () => {
    const device = onlineDevice();
    device.startSession();
    expect(device.status).toBe(DeviceStatus.InUse);
    expect(device.activeViewerCount).toBe(1);
  });

  it('não deixa iniciar sessão num dispositivo que não está online', () => {
    expect(() => offlineDevice().startSession()).toThrow(DeviceNotAvailableException);
  });

  it('encerrar a última sessão volta o status pra online', () => {
    const device = onlineDevice();
    device.startSession();
    device.endSession();
    expect(device.status).toBe(DeviceStatus.Online);
    expect(device.activeViewerCount).toBe(0);
  });

  it('pedir pra acordar exige que esteja hibernando', () => {
    expect(() => onlineDevice().requestWake()).toThrow(DeviceNotHibernatingException);
  });

  it('heartbeat depois de hibernando volta a online — é assim que o wake se resolve de verdade', () => {
    const hibernating = Device.reconstruct({
      ...onlineDevice().toSnapshot(),
      status: DeviceStatus.Hibernating,
    });

    hibernating.requestWake();
    hibernating.recordHeartbeat(new Date());

    expect(hibernating.status).toBe(DeviceStatus.Online);
  });

  it('dispara eventos de domínio nas transições de sessão', () => {
    const device = onlineDevice();
    device.startSession();
    device.endSession();

    expect(device.domainEvents.map((event) => event.eventName)).toEqual([
      'device.session.started',
      'device.session.ended',
    ]);
  });

  describe('heartbeat adaptativo', () => {
    it('é de 60s sem ninguém olhando', () => {
      expect(onlineDevice().nextHeartbeatIntervalSeconds()).toBe(60);
    });

    it('cai pra 2s assim que alguém conecta', () => {
      const device = onlineDevice();
      device.startSession();
      expect(device.nextHeartbeatIntervalSeconds()).toBe(2);
    });
  });

  describe('effectiveStatus (decadência sem worker em background)', () => {
    it('continua online pouco depois do heartbeat', () => {
      const device = onlineDevice();
      const soonAfter = new Date(Date.now() + 30_000);
      expect(device.effectiveStatus(soonAfter)).toBe(DeviceStatus.Online);
    });

    it('vira offline na leitura depois de muito tempo sem heartbeat, sem reescrever o status guardado', () => {
      const device = onlineDevice();
      const muchLater = new Date(Date.now() + 10 * 60 * 1000);
      expect(device.effectiveStatus(muchLater)).toBe(DeviceStatus.Offline);
      expect(device.status).toBe(DeviceStatus.Online);
    });

    it('um "EmUso" obsoleto também decai pra offline', () => {
      const device = onlineDevice();
      device.startSession();
      const muchLater = new Date(Date.now() + 10 * 60 * 1000);
      expect(device.effectiveStatus(muchLater)).toBe(DeviceStatus.Offline);
    });

    it('nunca mexe num status que já não é online/em uso', () => {
      const device = offlineDevice();
      const muchLater = new Date(Date.now() + 10 * 60 * 1000);
      expect(device.effectiveStatus(muchLater)).toBe(DeviceStatus.Offline);
    });

    it('sem heartbeat nenhum registrado, mesmo guardado como online, decai pra offline', () => {
      const device = Device.reconstruct({
        ...offlineDevice().toSnapshot(),
        status: DeviceStatus.Online,
        lastHeartbeatAt: null,
      });
      expect(device.effectiveStatus()).toBe(DeviceStatus.Offline);
    });
  });

  describe('startSession recusa um device que ficou obsoleto', () => {
    it('não deixa iniciar sessão num "online" guardado cujo heartbeat já é antigo demais', () => {
      const stale = Device.reconstruct({
        ...onlineDevice().toSnapshot(),
        lastHeartbeatAt: new Date(Date.now() - 10 * 60 * 1000),
      });
      expect(stale.effectiveStatus()).toBe(DeviceStatus.Offline);
    });
  });
});
