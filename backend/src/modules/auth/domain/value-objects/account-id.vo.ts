import { randomUUID } from 'node:crypto';

import { EntityId } from '@shared/domain/base/entity.base';

export class AccountId extends EntityId {
  static create(value?: string): AccountId {
    return new AccountId(value ?? randomUUID());
  }
}
