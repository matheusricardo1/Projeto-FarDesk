import type { UseCase } from '@shared/application/ports/use-case.port';
import type { ExternalProviderException } from '@shared/domain/exceptions/application.exception';
import type { Result } from '@shared/domain/types/result';
import type { LoginSessionNotFoundException } from '@modules/auth/domain/exceptions/login-session-not-found.exception';
import type { CompleteGoogleLoginDto } from '@modules/auth/application/dtos/complete-google-login.dto';

export const COMPLETE_GOOGLE_LOGIN_USE_CASE = Symbol('COMPLETE_GOOGLE_LOGIN_USE_CASE');

export type CompleteGoogleLoginError = LoginSessionNotFoundException | ExternalProviderException;

/** Chamado pelo callback do Google: troca o code pelo perfil, cria/atualiza a conta e emite a sessão. */
export type CompleteGoogleLoginUseCase = UseCase<
  CompleteGoogleLoginDto,
  Result<void, CompleteGoogleLoginError>
>;
