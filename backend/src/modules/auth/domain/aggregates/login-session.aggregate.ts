import { AggregateRoot } from '@shared/domain/base/aggregate-root.base';
import { LoginSessionId } from '@modules/auth/domain/value-objects/login-session-id.vo';
import { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';

export interface LoginSessionProps {
  id: LoginSessionId;
  status: LoginSessionStatus;
  createdAt: Date;
  accountId: string | null;
  accessToken: string | null;
  refreshToken: string | null;
  error: string | null;
}

/**
 * Ponte entre o navegador (onde o Google redireciona) e o app desktop (que
 * não recebe esse redirect). O app abre o navegador e faz polling desta
 * sessão até ela sair de `Pending` — assim os tokens chegam sem deep link.
 */
export class LoginSession extends AggregateRoot<LoginSessionId> {
  private props: LoginSessionProps;

  private constructor(props: LoginSessionProps) {
    super(props.id);
    this.props = props;
  }

  static start(now: Date): LoginSession {
    return new LoginSession({
      id: LoginSessionId.create(),
      status: LoginSessionStatus.Pending,
      createdAt: now,
      accountId: null,
      accessToken: null,
      refreshToken: null,
      error: null,
    });
  }

  static reconstruct(props: LoginSessionProps): LoginSession {
    return new LoginSession(props);
  }

  get status(): LoginSessionStatus {
    return this.props.status;
  }

  get accountId(): string | null {
    return this.props.accountId;
  }

  get accessToken(): string | null {
    return this.props.accessToken;
  }

  get refreshToken(): string | null {
    return this.props.refreshToken;
  }

  get error(): string | null {
    return this.props.error;
  }

  complete(props: { accountId: string; accessToken: string; refreshToken: string }): void {
    this.props.status = LoginSessionStatus.Completed;
    this.props.accountId = props.accountId;
    this.props.accessToken = props.accessToken;
    this.props.refreshToken = props.refreshToken;
  }

  fail(message: string): void {
    this.props.status = LoginSessionStatus.Failed;
    this.props.error = message;
  }

  toSnapshot(): Readonly<LoginSessionProps> {
    return { ...this.props };
  }
}
