import { Inject, Injectable } from '@nestjs/common';
import type { LoginSession as LoginSessionRow } from '@prisma/client';

import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import { PrismaService } from '@shared/infrastructure/database/prisma.service';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';

import { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import { LoginSessionId } from '@modules/auth/domain/value-objects/login-session-id.vo';
import type { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';

@Injectable()
export class PrismaLoginSessionRepository implements LoginSessionRepository {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher,
  ) {}

  async findById(id: string): Promise<LoginSession | null> {
    const row = await this.prisma.loginSession.findUnique({ where: { id } });
    return row ? this.toDomain(row) : null;
  }

  async save(session: LoginSession): Promise<void> {
    const snapshot = session.toSnapshot();
    await this.prisma.loginSession.upsert({
      where: { id: snapshot.id.value },
      create: {
        id: snapshot.id.value,
        status: snapshot.status,
        createdAt: snapshot.createdAt,
        accountId: snapshot.accountId,
        accessToken: snapshot.accessToken,
        refreshToken: snapshot.refreshToken,
        error: snapshot.error,
      },
      update: {
        status: snapshot.status,
        accountId: snapshot.accountId,
        accessToken: snapshot.accessToken,
        refreshToken: snapshot.refreshToken,
        error: snapshot.error,
      },
    });
    await publishDomainEvents(this.events, session);
  }

  async delete(id: string): Promise<void> {
    await this.prisma.loginSession.deleteMany({ where: { id } });
  }

  private toDomain(row: LoginSessionRow): LoginSession {
    return LoginSession.reconstruct({
      id: LoginSessionId.create(row.id),
      // Prisma gera o tipo do enum como union de string literais, não como
      // o enum nominal do domínio — mesmos valores em runtime.
      status: row.status as LoginSessionStatus,
      createdAt: row.createdAt,
      accountId: row.accountId,
      accessToken: row.accessToken,
      refreshToken: row.refreshToken,
      error: row.error,
    });
  }
}
