import { randomUUID } from 'node:crypto';

import { EntityId } from '@shared/domain/base/entity.base';

export class PairingRequestId extends EntityId {
  static create(value?: string): PairingRequestId {
    return new PairingRequestId(value ?? randomUUID());
  }
}
