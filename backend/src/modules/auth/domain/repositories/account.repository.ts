import type { Account } from '@modules/auth/domain/aggregates/account.aggregate';

export const ACCOUNT_REPOSITORY = Symbol('ACCOUNT_REPOSITORY');

export interface AccountRepository {
  findById(id: string): Promise<Account | null>;
  findByGoogleSub(googleSub: string): Promise<Account | null>;
  save(account: Account): Promise<void>;
}
