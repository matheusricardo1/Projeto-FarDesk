import type { LoginSessionStatus } from '@modules/auth/domain/value-objects/login-session-status.vo';
import type { AccountResponseDto } from '@modules/auth/application/dtos/account-response.dto';

/** O que o app recebe fazendo polling. */
export interface LoginSessionResponseDto {
  status: LoginSessionStatus;
  account: AccountResponseDto | null;
  accessToken: string | null;
  refreshToken: string | null;
  error: string | null;
}
