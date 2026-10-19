import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import { LoginSessionNotFoundException } from '@modules/auth/domain/exceptions/login-session-not-found.exception';
import { ACCOUNT_REPOSITORY } from '@modules/auth/domain/repositories/account.repository';
import type { AccountRepository } from '@modules/auth/domain/repositories/account.repository';
import { LOGIN_SESSION_REPOSITORY } from '@modules/auth/domain/repositories/login-session.repository';
import type { LoginSessionRepository } from '@modules/auth/domain/repositories/login-session.repository';
import { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';
import type { GetLoginSessionDto } from '@modules/auth/application/dtos/get-login-session.dto';
import type { LoginSessionResponseDto } from '@modules/auth/application/dtos/login-session-response.dto';
import { LoginSessionMapper } from '@modules/auth/application/mappers/login-session.mapper';
import type { GetLoginSessionUseCase } from '@modules/auth/application/ports/in/get-login-session.use-case';

/** Canal de entrega de uso único: lida com resultado final, a sessão é descartada. */
@Injectable()
export class GetLoginSessionUseCaseImpl implements GetLoginSessionUseCase {
  constructor(
    @Inject(LOGIN_SESSION_REPOSITORY) private readonly sessions: LoginSessionRepository,
    @Inject(ACCOUNT_REPOSITORY) private readonly accounts: AccountRepository,
  ) {}

  async execute(
    input: GetLoginSessionDto,
  ): Promise<Result<LoginSessionResponseDto, LoginSessionNotFoundException>> {
    const session = await this.sessions.findById(input.loginSessionId);
    if (!session) return Result.err(new LoginSessionNotFoundException(input.loginSessionId));

    if (session.status === LoginSessionStatus.Pending) {
      return Result.ok(LoginSessionMapper.toResponse(session, null));
    }

    await this.sessions.delete(input.loginSessionId);
    const account = session.accountId ? await this.accounts.findById(session.accountId) : null;
    return Result.ok(LoginSessionMapper.toResponse(session, account));
  }
}
