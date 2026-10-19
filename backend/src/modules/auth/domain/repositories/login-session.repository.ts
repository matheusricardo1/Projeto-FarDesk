import type { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';

export const LOGIN_SESSION_REPOSITORY = Symbol('LOGIN_SESSION_REPOSITORY');

export interface LoginSessionRepository {
  findById(id: string): Promise<LoginSession | null>;
  save(session: LoginSession): Promise<void>;
  /** Uso único: depois de lida com resultado final, a sessão é descartada. */
  delete(id: string): Promise<void>;
}
