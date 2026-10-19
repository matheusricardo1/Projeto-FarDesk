import { CompleteGoogleLoginUseCaseImpl } from '@modules/auth/application/use-cases/complete-google-login.use-case.impl';
import { GetLoginSessionUseCaseImpl } from '@modules/auth/application/use-cases/get-login-session.use-case.impl';
import { StartGoogleLoginUseCaseImpl } from '@modules/auth/application/use-cases/start-google-login.use-case.impl';
import type {
  GoogleOAuthGateway,
  GoogleProfile,
} from '@modules/auth/application/ports/out/google-oauth.gateway.port';
import type {
  IssuedTokens,
  SessionTokenIssuer,
  VerifiedAccessToken,
} from '@modules/auth/application/ports/out/session-token-issuer.port';
import type { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import type { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import { LoginSessionNotFoundException } from '@modules/auth/domain/exceptions/login-session-not-found.exception';
import type { AccountRepository } from '@modules/auth/domain/repositories/account.repository';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';
import type { UnitOfWork } from '@shared/application/ports/unit-of-work.port';
import { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import { Result } from '@shared/domain/types/result';

class FakeAccountRepository implements AccountRepository {
  readonly accounts = new Map<string, Account>();

  async findById(id: string): Promise<Account | null> {
    return this.accounts.get(id) ?? null;
  }

  async findByGoogleSub(googleSub: string): Promise<Account | null> {
    return [...this.accounts.values()].find((account) => account.googleSub === googleSub) ?? null;
  }

  async save(account: Account): Promise<void> {
    this.accounts.set(account.id.value, account);
  }
}

class FakeLoginSessionRepository implements LoginSessionRepository {
  readonly sessions = new Map<string, LoginSession>();

  async findById(id: string): Promise<LoginSession | null> {
    return this.sessions.get(id) ?? null;
  }

  async save(session: LoginSession): Promise<void> {
    this.sessions.set(session.id.value, session);
  }

  async delete(id: string): Promise<void> {
    this.sessions.delete(id);
  }
}

class FakeGoogleGateway implements GoogleOAuthGateway {
  constructor(private readonly profile: GoogleProfile | null) {}

  buildAuthorizationUrl(state: string): string {
    return `https://google.test/auth?state=${state}`;
  }

  async exchangeCodeForProfile(): Promise<Result<GoogleProfile, Error>> {
    return this.profile ? Result.ok(this.profile) : Result.err(new Error('code inválido'));
  }
}

class FakeTokenIssuer implements SessionTokenIssuer {
  issue(accountId: string): IssuedTokens {
    return { accessToken: `access-${accountId}`, refreshToken: `refresh-${accountId}` };
  }

  verifyAccessToken(): Result<VerifiedAccessToken, Error> {
    return Result.err(new Error('não usado'));
  }
}

const passthroughUnitOfWork: UnitOfWork = { runInTransaction: (work) => work() };

const PROFILE: GoogleProfile = {
  sub: 'google-123',
  email: 'Matheus@Gmail.com',
  name: 'Matheus',
  picture: null,
};

describe('Casos de uso de auth', () => {
  let accounts: FakeAccountRepository;
  let sessions: FakeLoginSessionRepository;

  beforeEach(() => {
    accounts = new FakeAccountRepository();
    sessions = new FakeLoginSessionRepository();
  });

  function complete(profile: GoogleProfile | null) {
    return new CompleteGoogleLoginUseCaseImpl(
      sessions,
      accounts,
      new FakeGoogleGateway(profile),
      new FakeTokenIssuer(),
      passthroughUnitOfWork,
    );
  }

  async function startLogin(): Promise<string> {
    const started = await new StartGoogleLoginUseCaseImpl(sessions, new FakeGoogleGateway(PROFILE)).execute();
    return started.value.loginSessionId;
  }

  it('fluxo completo: start → callback → polling entrega conta e tokens uma única vez', async () => {
    const loginSessionId = await startLogin();
    const poll = new GetLoginSessionUseCaseImpl(sessions, accounts);

    expect((await poll.execute({ loginSessionId })).value.status).toBe(LoginSessionStatus.Pending);

    const completed = await complete(PROFILE).execute({ loginSessionId, code: 'code' });
    expect(completed.isOk).toBe(true);

    const delivered = await poll.execute({ loginSessionId });
    expect(delivered.value.status).toBe(LoginSessionStatus.Completed);
    expect(delivered.value.account?.email).toBe('matheus@gmail.com');
    expect(delivered.value.accessToken).toMatch(/^access-/);

    expect((await poll.execute({ loginSessionId })).error).toBeInstanceOf(LoginSessionNotFoundException);
  });

  it('segundo login com o mesmo googleSub reaproveita a conta', async () => {
    await complete(PROFILE).execute({ loginSessionId: await startLogin(), code: 'code' });
    await complete({ ...PROFILE, name: 'Matheus R.' }).execute({
      loginSessionId: await startLogin(),
      code: 'code',
    });

    expect(accounts.accounts.size).toBe(1);
  });

  it('Google recusando o code marca a sessão como falha', async () => {
    const loginSessionId = await startLogin();

    const result = await complete(null).execute({ loginSessionId, code: 'ruim' });

    expect(result.error).toBeInstanceOf(ExternalProviderException);
    const delivered = await new GetLoginSessionUseCaseImpl(sessions, accounts).execute({ loginSessionId });
    expect(delivered.value.status).toBe(LoginSessionStatus.Failed);
    expect(accounts.accounts.size).toBe(0);
  });

  it('callback com sessão desconhecida falha', async () => {
    const result = await complete(PROFILE).execute({ loginSessionId: 'nao-existe', code: 'code' });

    expect(result.error).toBeInstanceOf(LoginSessionNotFoundException);
  });
});
