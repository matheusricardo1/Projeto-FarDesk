import { Inject, Injectable } from '@nestjs/common';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';
import type { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import type { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';
import { DevicePersistenceMapper } from '@modules/devices/infrastructure/persistence/mappers/device.persistence.mapper';
import type { DeviceRecord } from '@modules/devices/infrastructure/persistence/mappers/device.persistence.mapper';

/**
 * Adaptador de desenvolvimento. Guarda registros (não instâncias do
 * agregado), como um banco faria — trocar por Prisma é reimplementar esta
 * classe sobre o mesmo mapper. Semeado igual ao mock do app Flutter.
 */
@Injectable()
export class InMemoryDeviceRepository implements DeviceRepository {
  private readonly records = new Map<string, DeviceRecord>();

  constructor(@Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher) {
    this.seed();
  }

  async findById(id: DeviceId): Promise<Device | null> {
    const record = this.records.get(id.value);
    return record ? DevicePersistenceMapper.toDomain(record) : null;
  }

  async findAllByOwner(ownerId: string): Promise<Device[]> {
    return [...this.records.values()]
      .filter((record) => record.ownerId === ownerId)
      .map((record) => DevicePersistenceMapper.toDomain(record));
  }

  async save(device: Device): Promise<void> {
    this.records.set(device.id.value, DevicePersistenceMapper.toRecord(device));
    await publishDomainEvents(this.events, device);
  }

  private seed(): void {
    const ownerId = 'dev-user-1';
    const now = new Date().toISOString();
    const seeds: Array<Omit<DeviceRecord, 'ownerId' | 'lastHeartbeatAt'>> = [
      {
        id: 'pc-matheus',
        name: 'PC do Matheus',
        platform: DevicePlatform.Windows,
        status: DeviceStatus.Online,
        activeViewerCount: 0,
        hostCredential: null,
      },
      {
        id: 'pc-sala',
        name: 'PC da Sala',
        platform: DevicePlatform.Windows,
        status: DeviceStatus.InUse,
        activeViewerCount: 1,
        hostCredential: null,
      },
      {
        id: 'ps5',
        name: 'PS5',
        platform: DevicePlatform.PS5,
        status: DeviceStatus.Hibernating,
        activeViewerCount: 0,
        hostCredential: null,
      },
      {
        id: 'pc-trabalho',
        name: 'PC do Trabalho',
        platform: DevicePlatform.Windows,
        status: DeviceStatus.Offline,
        activeViewerCount: 0,
        hostCredential: null,
      },
      {
        id: 'notebook',
        name: 'Notebook',
        platform: DevicePlatform.Windows,
        status: DeviceStatus.Online,
        activeViewerCount: 0,
        hostCredential: null,
      },
      {
        id: 'servidor-home',
        name: 'Servidor Home',
        platform: DevicePlatform.Linux,
        status: DeviceStatus.Hibernating,
        activeViewerCount: 0,
        hostCredential: null,
      },
    ];

    for (const seed of seeds) {
      this.records.set(seed.id, {
        ...seed,
        ownerId,
        lastHeartbeatAt: seed.status === DeviceStatus.Offline ? null : now,
      });
    }
  }
}
