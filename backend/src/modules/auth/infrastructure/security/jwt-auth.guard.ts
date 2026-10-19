import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import type { CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { IS_PUBLIC_KEY } from '@shared/infrastructure/http/public.decorator';
import type { AuthenticatedUser } from '@modules/auth/application/dtos/authenticated-user.dto';
import { SESSION_TOKEN_ISSUER } from '@modules/auth/application/ports/out/session-token-issuer.port';
import type { SessionTokenIssuer } from '@modules/auth/application/ports/out/session-token-issuer.port';

/**
 * Registrado como `APP_GUARD` — protege a API inteira por padrão. Global (e
 * não `@UseGuards` por controller) porque um guard referenciado por classe
 * em outro módulo não resolve as próprias dependências de forma confiável.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    @Inject(SESSION_TOKEN_ISSUER) private readonly tokens: SessionTokenIssuer,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request & { user: AuthenticatedUser }>();
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Cabeçalho Authorization: Bearer <token> ausente.');
    }

    const result = this.tokens.verifyAccessToken(header.slice('Bearer '.length));
    if (result.isErr) throw new UnauthorizedException(result.error.message);

    request.user = { userId: result.value.accountId };
    return true;
  }
}
