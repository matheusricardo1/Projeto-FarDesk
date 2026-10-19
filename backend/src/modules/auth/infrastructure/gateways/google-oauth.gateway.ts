import { Injectable } from '@nestjs/common';

import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import type { GoogleOAuthConfig } from '@shared/infrastructure/config/app-config.service';
import { Result } from '@shared/domain/types/result';
import type {
  GoogleOAuthGateway,
  GoogleProfile,
} from '@modules/auth/application/ports/out/google-oauth.gateway.port';

const AUTHORIZATION_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const USERINFO_ENDPOINT = 'https://openidconnect.googleapis.com/v1/userinfo';

interface GoogleTokenResponse {
  access_token: string;
}

interface GoogleUserInfoResponse {
  sub: string;
  email: string;
  name: string;
  picture?: string;
}

/**
 * Adaptador real. Pede o perfil ao endpoint OIDC de userinfo com o
 * `access_token` em vez de verificar a assinatura do `id_token` à mão — o
 * próprio Google valida. As env vars só são exigidas no uso, não no boot.
 */
@Injectable()
export class GoogleOAuthApiGateway implements GoogleOAuthGateway {
  constructor(private readonly config: AppConfigService) {}

  buildAuthorizationUrl(state: string): string {
    const config = this.loadConfig();
    const params = new URLSearchParams({
      client_id: config.clientId,
      redirect_uri: config.redirectUri,
      response_type: 'code',
      scope: 'openid email profile',
      state,
      prompt: 'select_account',
    });
    return `${AUTHORIZATION_ENDPOINT}?${params.toString()}`;
  }

  async exchangeCodeForProfile(code: string): Promise<Result<GoogleProfile, Error>> {
    const config = this.loadConfig();

    try {
      const tokenResponse = await fetch(TOKEN_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          code,
          client_id: config.clientId,
          client_secret: config.clientSecret,
          redirect_uri: config.redirectUri,
          grant_type: 'authorization_code',
        }).toString(),
      });
      if (!tokenResponse.ok) {
        return Result.err(new Error(`Google recusou o code (HTTP ${tokenResponse.status}).`));
      }
      const { access_token: accessToken } = (await tokenResponse.json()) as GoogleTokenResponse;

      const userInfoResponse = await fetch(USERINFO_ENDPOINT, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (!userInfoResponse.ok) {
        return Result.err(new Error(`Falha ao buscar perfil no Google (HTTP ${userInfoResponse.status}).`));
      }
      const info = (await userInfoResponse.json()) as GoogleUserInfoResponse;

      return Result.ok({ sub: info.sub, email: info.email, name: info.name, picture: info.picture ?? null });
    } catch (error) {
      return Result.err(
        error instanceof Error ? error : new Error('Falha desconhecida ao autenticar com o Google.'),
      );
    }
  }

  private loadConfig(): GoogleOAuthConfig {
    const google = this.config.google;
    if (!google) {
      throw new Error(
        'Login com Google não configurado: defina GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET e GOOGLE_REDIRECT_URI.',
      );
    }
    return google;
  }
}
