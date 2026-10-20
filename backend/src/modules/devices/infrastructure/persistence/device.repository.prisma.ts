import { Inject, Injectable } from '@nestjs/common';
import type { Device as DeviceRow } from '@prisma/client';

import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import { PrismaService } from '@shared/infrastructure/database/prisma.service';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';

import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
import type { DeviceRepository } from '@modules/devices/domain/repositories/device.repository';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import type { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

@Injectable()
export class PrismaDeviceRepository implements DeviceRepository {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher,
  ) {}

  async findById(id: DeviceId): Promise<Device | null> {
    const row = await this.prisma.device.findUnique({ where: { id: id.value } });
    return row ? this.toDomain(row) : null;
  }

  async findAllByOwner(ownerId: string): Promise<Device[]> {
    const rows = await this.prisma.device.findMany({ where: { ownerId } });
    return rows.map((row) => this.toDomain(row));
  }

  async save(device: Device): Promise<void> {
    const snapshot = device.toSnapshot();
    await this.prisma.device.upsert({
      where: { id: snapshot.id.value },
      create: {
        id: snapshot.id.value,
        ownerId: snapshot.ownerId,
        name: snapshot.name,
        platform: snapshot.platform,
        status: snapshot.status,
        lastHeartbeatAt: snapshot.lastHeartbeatAt,
        activeViewerCount: snapshot.activeViewerCount,
        hostCredentialCiphertext: snapshot.hostCredential?.ciphertext ?? null,
        hostCredentialIv: snapshot.hostCredential?.iv ?? null,
        hostCredentialAuthTag: snapshot.hostCredential?.authTag ?? null,
      },
      update: {
        name: snapshot.name,
        platform: snapshot.platform,
        status: snapshot.status,
        lastHeartbeatAt: snapshot.lastHeartbeatAt,
        activeViewerCount: snapshot.activeViewerCount,
        hostCredentialCiphertext: snapshot.hostCredential?.ciphertext ?? null,
        hostCredentialIv: snapshot.hostCredential?.iv ?? null,
        hostCredentialAuthTag: snapshot.hostCredential?.authTag ?? null,
      },
    });
    await publishDomainEvents(this.events, device);
  }

  private toDomain(row: DeviceRow): Device {
    return Device.reconstruct({
      id: DeviceId.create(row.id),
      ownerId: row.ownerId,
      name: row.name,
      // Prisma gera o tipo do enum como union de string literais, não como
      // o enum nominal do domínio — mesmos valores em runtime, cast só pra
      // alinhar o tipo.
      platform: row.platform as DevicePlatform,
      status: row.status as DeviceStatus,
      lastHeartbeatAt: row.lastHeartbeatAt,
      activeViewerCount: row.activeViewerCount,
      hostCredential:
        row.hostCredentialCiphertext && row.hostCredentialIv && row.hostCredentialAuthTag
          ? {
              ciphertext: row.hostCredentialCiphertext,
              iv: row.hostCredentialIv,
              authTag: row.hostCredentialAuthTag,
            }
          : null,
    });
  }
}
