import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import { LOGIN_SESSION_REPOSITORY } from '@modules/auth/domain/repositories/login-session.repository';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import type { StartGoogleLoginResponseDto } from '@modules/auth/application/dtos/start-google-login-response.dto';
import type { StartGoogleLoginUseCase } from '@modules/auth/application/ports/in/start-google-login.use-case';
import { GOOGLE_OAUTH_GATEWAY } from '@modules/auth/application/ports/out/google-oauth.gateway.port';
import type { GoogleOAuthGateway } from '@modules/auth/application/ports/out/google-oauth.gateway.port';

@Injectable()
export class StartGoogleLoginUseCaseImpl implements StartGoogleLoginUseCase {
  constructor(
    @Inject(LOGIN_SESSION_REPOSITORY) private readonly sessions: LoginSessionRepository,
    @Inject(GOOGLE_OAUTH_GATEWAY) private readonly google: GoogleOAuthGateway,
  ) {}

  async execute(): Promise<Result<StartGoogleLoginResponseDto, never>> {
    const session = LoginSession.start(new Date());
    await this.sessions.save(session);

    return Result.ok({
      loginSessionId: session.id.value,
      authorizationUrl: this.google.buildAuthorizationUrl(session.id.value),
    });
  }
}
