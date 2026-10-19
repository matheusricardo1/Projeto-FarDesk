import { DomainEvent } from '@shared/domain/base/domain-event.base';

export class AccountLoggedInEvent extends DomainEvent {
  readonly eventName = 'account.logged_in';

  constructor(
    readonly accountId: string,
    readonly email: string,
  ) {
    super();
  }
}
