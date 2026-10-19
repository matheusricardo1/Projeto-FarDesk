import { randomUUID } from 'node:crypto';

import { EntityId } from '@shared/domain/base/entity.base';

export class LoginSessionId extends EntityId {
  static create(value?: string): LoginSessionId {
    return new LoginSessionId(value ?? randomUUID());
  }
}
