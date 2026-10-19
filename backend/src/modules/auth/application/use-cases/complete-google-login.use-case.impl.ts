import { Inject, Injectable } from '@nestjs/common';

import { UNIT_OF_WORK } from '@shared/application/ports/unit-of-work.port';
import type { UnitOfWork } from '@shared/application/ports/unit-of-work.port';
import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';
import { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import { LoginSessionNotFoundException } from '@modules/auth/domain/exceptions/login-session-not-found.exception';
import { ACCOUNT_REPOSITORY } from '@modules/auth/domain/repositories/account.repository';
import type { AccountRepository } from '@modules/auth/domain/repositories/account.repository';
import { LOGIN_SESSION_REPOSITORY } from '@modules/auth/domain/repositories/login-session.repository';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import type { CompleteGoogleLoginDto } from '@modules/auth/application/dtos/complete-google-login.dto';
import type {
  CompleteGoogleLoginError,
  CompleteGoogleLoginUseCase,
} from '@modules/auth/application/ports/in/complete-google-login.use-case';
import { GOOGLE_OAUTH_GATEWAY } from '@modules/auth/application/ports/out/google-oauth.gateway.port';
import type { GoogleOAuthGateway } from '@modules/auth/application/ports/out/google-oauth.gateway.port';
import { SESSION_TOKEN_ISSUER } from '@modules/auth/application/ports/out/session-token-issuer.port';
import type { SessionTokenIssuer } from '@modules/auth/application/ports/out/session-token-issuer.port';

@Injectable()
export class CompleteGoogleLoginUseCaseImpl implements CompleteGoogleLoginUseCase {
  constructor(
    @Inject(LOGIN_SESSION_REPOSITORY) private readonly sessions: LoginSessionRepository,
    @Inject(ACCOUNT_REPOSITORY) private readonly accounts: AccountRepository,
    @Inject(GOOGLE_OAUTH_GATEWAY) private readonly google: GoogleOAuthGateway,
    @Inject(SESSION_TOKEN_ISSUER) private readonly tokens: SessionTokenIssuer,
    @Inject(UNIT_OF_WORK) private readonly unitOfWork: UnitOfWork,
  ) {}

  async execute(input: CompleteGoogleLoginDto): Promise<Result<void, CompleteGoogleLoginError>> {
    const session = await this.sessions.findById(input.loginSessionId);
    if (!session) return Result.err(new LoginSessionNotFoundException(input.loginSessionId));

    const profileResult = await this.google.exchangeCodeForProfile(input.code);
    if (profileResult.isErr) {
      session.fail(profileResult.error.message);
      await this.sessions.save(session);
      return Result.err(new ExternalProviderException('Google', profileResult.error.message));
    }

    const profile = profileResult.value;
    const now = new Date();
    const account =
      (await this.accounts.findByGoogleSub(profile.sub)) ??
      Account.createFromGoogle({
        googleSub: profile.sub,
        email: profile.email,
        displayName: profile.name,
        avatarUrl: profile.picture,
        now,
      });
    account.recordGoogleLogin({
      email: profile.email,
      displayName: profile.name,
      avatarUrl: profile.picture,
      now,
    });

    const issued = this.tokens.issue(account.id.value);
    session.complete({
      accountId: account.id.value,
      accessToken: issued.accessToken,
      refreshToken: issued.refreshToken,
    });

    // Conta e sessão mudam juntas — uma sem a outra deixaria o app sem token ou com token órfão.
    await this.unitOfWork.runInTransaction(async () => {
      await this.accounts.save(account);
      await this.sessions.save(session);
    });

    return Result.ok(undefined);
  }
}
