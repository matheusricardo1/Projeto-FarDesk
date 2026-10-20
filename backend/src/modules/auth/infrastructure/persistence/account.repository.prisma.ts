import { Inject, Injectable } from '@nestjs/common';
import type { Account as AccountRow } from '@prisma/client';

import type { DomainEventPublisher } from '@shared/application/ports/event-publisher.port';
import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import { PrismaService } from '@shared/infrastructure/database/prisma.service';
import { publishDomainEvents } from '@shared/infrastructure/messaging/publish-domain-events';

import { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import type { AccountRepository } from '@modules/auth/domain/repositories/account.repository';
import { AccountId } from '@modules/auth/domain/value-objects/account-id.vo';
import { Email } from '@modules/auth/domain/value-objects/email.vo';

@Injectable()
export class PrismaAccountRepository implements AccountRepository {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(DOMAIN_EVENT_PUBLISHER) private readonly events: DomainEventPublisher,
  ) {}

  async findById(id: string): Promise<Account | null> {
    const row = await this.prisma.account.findUnique({ where: { id } });
    return row ? this.toDomain(row) : null;
  }

  async findByGoogleSub(googleSub: string): Promise<Account | null> {
    const row = await this.prisma.account.findUnique({ where: { googleSub } });
    return row ? this.toDomain(row) : null;
  }

  async save(account: Account): Promise<void> {
    const snapshot = account.toSnapshot();
    await this.prisma.account.upsert({
      where: { id: snapshot.id.value },
      create: {
        id: snapshot.id.value,
        googleSub: snapshot.googleSub,
        email: snapshot.email.value,
        displayName: snapshot.displayName,
        avatarUrl: snapshot.avatarUrl,
        createdAt: snapshot.createdAt,
        lastLoginAt: snapshot.lastLoginAt,
      },
      update: {
        email: snapshot.email.value,
        displayName: snapshot.displayName,
        avatarUrl: snapshot.avatarUrl,
        lastLoginAt: snapshot.lastLoginAt,
      },
    });
    await publishDomainEvents(this.events, account);
  }

  private toDomain(row: AccountRow): Account {
    return Account.reconstruct({
      id: AccountId.create(row.id),
      googleSub: row.googleSub,
      email: Email.create(row.email),
      displayName: row.displayName,
      avatarUrl: row.avatarUrl,
      createdAt: row.createdAt,
      lastLoginAt: row.lastLoginAt,
    });
  }
}
