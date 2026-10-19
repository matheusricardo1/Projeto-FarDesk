import { randomUUID } from 'node:crypto';

import { EntityId } from '@shared/domain/base/entity.base';

export class IntegrationId extends EntityId {
  static create(value?: string): IntegrationId {
    return new IntegrationId(value ?? randomUUID());
  }
}
