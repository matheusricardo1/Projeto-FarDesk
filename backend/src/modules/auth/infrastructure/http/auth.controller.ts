import { Controller, Get, HttpCode, HttpStatus, Inject, Param, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';

import { Public } from '@shared/infrastructure/http/public.decorator';
import type { LoginSessionResponseDto } from '@modules/auth/application/dtos/login-session-response.dto';
import type { StartGoogleLoginResponseDto } from '@modules/auth/application/dtos/start-google-login-response.dto';
import { COMPLETE_GOOGLE_LOGIN_USE_CASE } from '@modules/auth/application/ports/in/complete-google-login.use-case';
import type { CompleteGoogleLoginUseCase } from '@modules/auth/application/ports/in/complete-google-login.use-case';
import { GET_LOGIN_SESSION_USE_CASE } from '@modules/auth/application/ports/in/get-login-session.use-case';
import type { GetLoginSessionUseCase } from '@modules/auth/application/ports/in/get-login-session.use-case';
import { START_GOOGLE_LOGIN_USE_CASE } from '@modules/auth/application/ports/in/start-google-login.use-case';
import type { StartGoogleLoginUseCase } from '@modules/auth/application/ports/in/start-google-login.use-case';
import { AuthCallbackPresenter } from '@modules/auth/infrastructure/http/auth-callback.presenter';

/**
 * Tudo `@Public()` — é o trecho que roda antes de existir sessão. O que
 * protege contra abuso é o `code` do Google (uso único, expira em minutos)
 * e o id da `LoginSession` (UUID imprevisível, consumido na primeira leitura).
 */
@Controller('auth/google')
export class AuthController {
  constructor(
    @Inject(START_GOOGLE_LOGIN_USE_CASE) private readonly startGoogleLogin: StartGoogleLoginUseCase,
    @Inject(COMPLETE_GOOGLE_LOGIN_USE_CASE) private readonly completeGoogleLogin: CompleteGoogleLoginUseCase,
    @Inject(GET_LOGIN_SESSION_USE_CASE) private readonly getLoginSession: GetLoginSessionUseCase,
  ) {}

  @Public()
  @Post('start')
  @HttpCode(HttpStatus.OK)
  async start(): Promise<StartGoogleLoginResponseDto> {
    const result = await this.startGoogleLogin.execute();
    return result.value;
  }

  @Public()
  @Get('callback')
  async callback(
    @Query('state') state: string,
    @Query('code') code: string,
    @Res() res: Response,
  ): Promise<void> {
    const result = await this.completeGoogleLogin.execute({ loginSessionId: state, code });
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    if (result.isErr) {
      res.status(HttpStatus.BAD_REQUEST).send(AuthCallbackPresenter.failure(result.error.message));
      return;
    }
    res.status(HttpStatus.OK).send(AuthCallbackPresenter.success());
  }

  @Public()
  @Get('sessions/:id')
  async session(@Param('id') id: string): Promise<LoginSessionResponseDto> {
    const result = await this.getLoginSession.execute({ loginSessionId: id });
    if (result.isErr) throw result.error;
    return result.value;
  }
}
