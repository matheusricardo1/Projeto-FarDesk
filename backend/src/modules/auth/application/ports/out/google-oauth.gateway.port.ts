import type { Result } from '@shared/domain/types/result';

export const GOOGLE_OAUTH_GATEWAY = Symbol('GOOGLE_OAUTH_GATEWAY');

export interface GoogleProfile {
  readonly sub: string;
  readonly email: string;
  readonly name: string;
  readonly picture: string | null;
}

/**
 * `state` é sempre o id da `LoginSession` — já é o valor imprevisível que
 * protege o callback contra CSRF.
 */
export interface GoogleOAuthGateway {
  buildAuthorizationUrl(state: string): string;
  exchangeCodeForProfile(code: string): Promise<Result<GoogleProfile, Error>>;
}
