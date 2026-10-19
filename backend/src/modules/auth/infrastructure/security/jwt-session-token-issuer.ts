import { createHmac, timingSafeEqual } from 'node:crypto';

import { Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import type {
  IssuedTokens,
  SessionTokenIssuer,
  VerifiedAccessToken,
} from '@modules/auth/application/ports/out/session-token-issuer.port';

const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7;
const REFRESH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;

interface TokenPayload {
  sub: string;
  type: 'access' | 'refresh';
  iat: number;
  exp: number;
}

function base64url(input: Buffer): string {
  return input.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64urlDecode(input: string): Buffer {
  return Buffer.from(input.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

/** JWT HS256 com `node:crypto` — é só HMAC + base64url, não justifica uma dependência. */
@Injectable()
export class JwtSessionTokenIssuer implements SessionTokenIssuer {
  private readonly secret: string;

  constructor(config: AppConfigService) {
    this.secret = config.authJwtSecret;
  }

  issue(accountId: string): IssuedTokens {
    const now = Math.floor(Date.now() / 1000);
    return {
      accessToken: this.sign({
        sub: accountId,
        type: 'access',
        iat: now,
        exp: now + ACCESS_TOKEN_TTL_SECONDS,
      }),
      refreshToken: this.sign({
        sub: accountId,
        type: 'refresh',
        iat: now,
        exp: now + REFRESH_TOKEN_TTL_SECONDS,
      }),
    };
  }

  verifyAccessToken(token: string): Result<VerifiedAccessToken, Error> {
    const payloadResult = this.verify(token);
    if (payloadResult.isErr) return Result.err(payloadResult.error);
    if (payloadResult.value.type !== 'access') return Result.err(new Error('Token não é um access token.'));
    return Result.ok({ accountId: payloadResult.value.sub });
  }

  private sign(payload: TokenPayload): string {
    const header = base64url(Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
    const body = base64url(Buffer.from(JSON.stringify(payload)));
    return `${header}.${body}.${this.signature(header, body)}`;
  }

  private verify(token: string): Result<TokenPayload, Error> {
    const parts = token.split('.');
    if (parts.length !== 3) return Result.err(new Error('Token malformado.'));
    const [header, body, signature] = parts as [string, string, string];

    const actual = Buffer.from(signature);
    const expected = Buffer.from(this.signature(header, body));
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) {
      return Result.err(new Error('Assinatura do token inválida.'));
    }

    const payload = JSON.parse(base64urlDecode(body).toString('utf8')) as TokenPayload;
    if (payload.exp < Math.floor(Date.now() / 1000)) return Result.err(new Error('Token expirado.'));
    return Result.ok(payload);
  }

  private signature(header: string, body: string): string {
    return base64url(createHmac('sha256', this.secret).update(`${header}.${body}`).digest());
  }
}
