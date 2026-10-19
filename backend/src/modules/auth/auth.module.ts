import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';

import { COMPLETE_GOOGLE_LOGIN_USE_CASE } from '@modules/auth/application/ports/in/complete-google-login.use-case';
import { GET_LOGIN_SESSION_USE_CASE } from '@modules/auth/application/ports/in/get-login-session.use-case';
import { START_GOOGLE_LOGIN_USE_CASE } from '@modules/auth/application/ports/in/start-google-login.use-case';
import { GOOGLE_OAUTH_GATEWAY } from '@modules/auth/application/ports/out/google-oauth.gateway.port';
import { SESSION_TOKEN_ISSUER } from '@modules/auth/application/ports/out/session-token-issuer.port';
import { CompleteGoogleLoginUseCaseImpl } from '@modules/auth/application/use-cases/complete-google-login.use-case.impl';
import { GetLoginSessionUseCaseImpl } from '@modules/auth/application/use-cases/get-login-session.use-case.impl';
import { StartGoogleLoginUseCaseImpl } from '@modules/auth/application/use-cases/start-google-login.use-case.impl';
import { ACCOUNT_REPOSITORY } from '@modules/auth/domain/repositories/account.repository';
import { LOGIN_SESSION_REPOSITORY } from '@modules/auth/domain/repositories/login-session.repository';
import { GoogleOAuthApiGateway } from '@modules/auth/infrastructure/gateways/google-oauth.gateway';
import { AuthController } from '@modules/auth/infrastructure/http/auth.controller';
import { AuthEventsListener } from '@modules/auth/infrastructure/messaging/auth-events.listener';
import { InMemoryAccountRepository } from '@modules/auth/infrastructure/persistence/account.repository.impl';
import { InMemoryLoginSessionRepository } from '@modules/auth/infrastructure/persistence/login-session.repository.impl';
import { JwtAuthGuard } from '@modules/auth/infrastructure/security/jwt-auth.guard';
import { JwtSessionTokenIssuer } from '@modules/auth/infrastructure/security/jwt-session-token-issuer';

@Module({
  controllers: [AuthController],
  providers: [
    { provide: START_GOOGLE_LOGIN_USE_CASE, useClass: StartGoogleLoginUseCaseImpl },
    { provide: COMPLETE_GOOGLE_LOGIN_USE_CASE, useClass: CompleteGoogleLoginUseCaseImpl },
    { provide: GET_LOGIN_SESSION_USE_CASE, useClass: GetLoginSessionUseCaseImpl },
    { provide: ACCOUNT_REPOSITORY, useClass: InMemoryAccountRepository },
    { provide: LOGIN_SESSION_REPOSITORY, useClass: InMemoryLoginSessionRepository },
    { provide: GOOGLE_OAUTH_GATEWAY, useClass: GoogleOAuthApiGateway },
    { provide: SESSION_TOKEN_ISSUER, useClass: JwtSessionTokenIssuer },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    AuthEventsListener,
  ],
})
export class AuthModule {}
