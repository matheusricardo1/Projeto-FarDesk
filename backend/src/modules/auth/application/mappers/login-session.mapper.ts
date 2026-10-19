import type { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import type { LoginSession } from '@modules/auth/domain/aggregates/login-session.aggregate';
import type { LoginSessionResponseDto } from '@modules/auth/application/dtos/login-session-response.dto';
import { AccountMapper } from '@modules/auth/application/mappers/account.mapper';

export class LoginSessionMapper {
  static toResponse(session: LoginSession, account: Account | null): LoginSessionResponseDto {
    return {
      status: session.status,
      account: account ? AccountMapper.toResponse(account) : null,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      error: session.error,
    };
  }
}
