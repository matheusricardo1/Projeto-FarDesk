import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { StartGoogleLoginResponseDto } from '@modules/auth/application/dtos/start-google-login-response.dto';

export const START_GOOGLE_LOGIN_USE_CASE = Symbol('START_GOOGLE_LOGIN_USE_CASE');

/** O app chama isto, abre `authorizationUrl` no navegador e faz polling de `loginSessionId`. */
export type StartGoogleLoginUseCase = UseCase<void, Result<StartGoogleLoginResponseDto, never>>;
