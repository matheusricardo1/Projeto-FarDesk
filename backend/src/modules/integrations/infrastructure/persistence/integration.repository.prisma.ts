import { Inject, Injectable } from '@nestjs/common';
import type { Integration as IntegrationRow } from '@prisma/client';

import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import { PrismaService } from '@shared/infrastructure/database/prisma.service';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';

import { Integration } from '@modules/integrations/domain/aggregates/integration.aggregate';
import type { IntegrationRepository } from '@modules/integrations/domain/repositories/integration.repository';
import type { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';
import { IntegrationId } from '@modules/integrations/domain/value-objects/integration-id.vo';
import type { IntegrationStatus } from '@modules/integrations/domain/value-objects/integration-status.vo';

@Injectable()
export class PrismaIntegrationRepository implements IntegrationRepository {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher,
  ) {}

  async findByOwnerAndPlatform(ownerId: string, platform: IntegrationPlatform): Promise<Integration | null> {
    const row = await this.prisma.integration.findUnique({ where: { ownerId_platform: { ownerId, platform } } });
    return row ? this.toDomain(row) : null;
  }

  async findAllByOwner(ownerId: string): Promise<Integration[]> {
    const rows = await this.prisma.integration.findMany({ where: { ownerId } });
    return rows.map((row) => this.toDomain(row));
  }

  async save(integration: Integration): Promise<void> {
    const snapshot = integration.toSnapshot();
    await this.prisma.integration.upsert({
      where: { id: snapshot.id.value },
      create: {
        id: snapshot.id.value,
        ownerId: snapshot.ownerId,
        platform: snapshot.platform,
        status: snapshot.status,
        credentialCiphertext: snapshot.credential?.ciphertext ?? null,
        credentialIv: snapshot.credential?.iv ?? null,
        credentialAuthTag: snapshot.credential?.authTag ?? null,
        connectedAt: snapshot.connectedAt,
        lastValidatedAt: snapshot.lastValidatedAt,
        lastError: snapshot.lastError,
      },
      update: {
        status: snapshot.status,
        credentialCiphertext: snapshot.credential?.ciphertext ?? null,
        credentialIv: snapshot.credential?.iv ?? null,
        credentialAuthTag: snapshot.credential?.authTag ?? null,
        connectedAt: snapshot.connectedAt,
        lastValidatedAt: snapshot.lastValidatedAt,
        lastError: snapshot.lastError,
      },
    });
    await publishDomainEvents(this.events, integration);
  }

  private toDomain(row: IntegrationRow): Integration {
    const hasCredential = row.credentialCiphertext && row.credentialIv && row.credentialAuthTag;
    return Integration.reconstruct({
      id: IntegrationId.create(row.id),
      ownerId: row.ownerId,
      // Prisma gera o tipo dos enums como union de string literais, não
      // como o enum nominal do domínio — mesmos valores em runtime.
      platform: row.platform as IntegrationPlatform,
      status: row.status as IntegrationStatus,
      credential: hasCredential
        ? { ciphertext: row.credentialCiphertext!, iv: row.credentialIv!, authTag: row.credentialAuthTag! }
        : null,
      connectedAt: row.connectedAt,
      lastValidatedAt: row.lastValidatedAt,
      lastError: row.lastError,
    });
  }
}
