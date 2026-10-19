import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';

import type { AccountLoggedInEvent } from '@modules/auth/domain/events/account-logged-in.event';

@Injectable()
export class AuthEventsListener {
  private readonly logger = new Logger(AuthEventsListener.name);

  @OnEvent('account.logged_in')
  onAccountLoggedIn(event: AccountLoggedInEvent): void {
    this.logger.log(`Login: account=${event.accountId} email=${event.email}`);
  }
}
