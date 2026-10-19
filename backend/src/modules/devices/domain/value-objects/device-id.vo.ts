import { randomUUID } from 'node:crypto';

import { EntityId } from '@shared/domain/base/entity.base';

export class DeviceId extends EntityId {
  static create(value?: string): DeviceId {
    return new DeviceId(value ?? randomUUID());
  }
}
