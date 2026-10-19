import { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import { LoginSessionId } from '@modules/auth/domain/value-objects/login-session-id.vo';
import type { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';

export interface LoginSessionRecord {
  id: string;
  status: LoginSessionStatus;
  createdAt: string;
  accountId: string | null;
  accessToken: string | null;
  refreshToken: string | null;
  error: string | null;
}

export class LoginSessionPersistenceMapper {
  static toRecord(session: LoginSession): LoginSessionRecord {
    const snapshot = session.toSnapshot();
    return {
      id: snapshot.id.value,
      status: snapshot.status,
      createdAt: snapshot.createdAt.toISOString(),
      accountId: snapshot.accountId,
      accessToken: snapshot.accessToken,
      refreshToken: snapshot.refreshToken,
      error: snapshot.error,
    };
  }

  static toDomain(record: LoginSessionRecord): LoginSession {
    return LoginSession.reconstruct({
      id: LoginSessionId.create(record.id),
      status: record.status,
      createdAt: new Date(record.createdAt),
      accountId: record.accountId,
      accessToken: record.accessToken,
      refreshToken: record.refreshToken,
      error: record.error,
    });
  }
}
