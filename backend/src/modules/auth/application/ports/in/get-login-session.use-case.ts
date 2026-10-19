import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { LoginSessionNotFoundException } from '@modules/auth/domain/exceptions/login-session-not-found.exception';
import type { GetLoginSessionDto } from '@modules/auth/application/dtos/get-login-session.dto';
import type { LoginSessionResponseDto } from '@modules/auth/application/dtos/login-session-response.dto';

export const GET_LOGIN_SESSION_USE_CASE = Symbol('GET_LOGIN_SESSION_USE_CASE');

export type GetLoginSessionUseCase = UseCase<
  GetLoginSessionDto,
  Result<LoginSessionResponseDto, LoginSessionNotFoundException>
>;
