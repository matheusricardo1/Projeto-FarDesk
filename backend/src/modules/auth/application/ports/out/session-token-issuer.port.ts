import type { Result } from '@shared/domain/types/result';

export const SESSION_TOKEN_ISSUER = Symbol('SESSION_TOKEN_ISSUER');

export interface IssuedTokens {
  readonly accessToken: string;
  readonly refreshToken: string;
}

export interface VerifiedAccessToken {
  readonly accountId: string;
}

/** Sessão própria do FarDesk — depois do login, o Google não participa de mais nada. */
export interface SessionTokenIssuer {
  issue(accountId: string): IssuedTokens;
  verifyAccessToken(token: string): Result<VerifiedAccessToken, Error>;
}
