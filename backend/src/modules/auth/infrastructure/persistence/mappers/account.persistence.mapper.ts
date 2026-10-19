import { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import { AccountId } from '@modules/auth/domain/value-objects/account-id.vo';
import { Email } from '@modules/auth/domain/value-objects/email.vo';

export interface AccountRecord {
  id: string;
  googleSub: string;
  email: string;
  displayName: string;
  avatarUrl: string | null;
  createdAt: string;
  lastLoginAt: string;
}

export class AccountPersistenceMapper {
  static toRecord(account: Account): AccountRecord {
    const snapshot = account.toSnapshot();
    return {
      id: snapshot.id.value,
      googleSub: snapshot.googleSub,
      email: snapshot.email.value,
      displayName: snapshot.displayName,
      avatarUrl: snapshot.avatarUrl,
      createdAt: snapshot.createdAt.toISOString(),
      lastLoginAt: snapshot.lastLoginAt.toISOString(),
    };
  }

  static toDomain(record: AccountRecord): Account {
    return Account.reconstruct({
      id: AccountId.create(record.id),
      googleSub: record.googleSub,
      email: Email.create(record.email),
      displayName: record.displayName,
      avatarUrl: record.avatarUrl,
      createdAt: new Date(record.createdAt),
      lastLoginAt: new Date(record.lastLoginAt),
    });
  }
}
