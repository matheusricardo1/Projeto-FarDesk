import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { EnvironmentVariables } from '@shared/infrastructure/config/env.validation';
import { NodeEnv } from '@shared/infrastructure/config/env.validation';

export interface GoogleOAuthConfig {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly redirectUri: string;
}

const DEFAULT_DEV_ORIGINS = ['http://localhost:3000', 'http://localhost:8080'];

/** Único ponto de leitura de configuração — nenhum adapter lê `process.env` direto. */
@Injectable()
export class AppConfigService {
  constructor(private readonly config: ConfigService<EnvironmentVariables, true>) {}

  get nodeEnv(): NodeEnv {
    return this.config.get('NODE_ENV', { infer: true });
  }

  get isProduction(): boolean {
    return this.nodeEnv === NodeEnv.Production;
  }

  get port(): number {
    return this.config.get('PORT', { infer: true });
  }

  get authJwtSecret(): string {
    return this.config.get('AUTH_JWT_SECRET', { infer: true });
  }

  get integrationsMasterKey(): string {
    return this.config.get('INTEGRATIONS_MASTER_KEY', { infer: true });
  }

  /** `null` enquanto o login com Google não foi configurado. */
  get google(): GoogleOAuthConfig | null {
    const clientId = this.config.get('GOOGLE_CLIENT_ID', { infer: true });
    const clientSecret = this.config.get('GOOGLE_CLIENT_SECRET', { infer: true });
    const redirectUri = this.config.get('GOOGLE_REDIRECT_URI', { infer: true });
    if (!clientId || !clientSecret || !redirectUri) return null;
    return { clientId, clientSecret, redirectUri };
  }

  get allowedOrigins(): string[] {
    const raw = this.config.get('ALLOWED_ORIGINS', { infer: true });
    if (!raw) return this.isProduction ? [] : DEFAULT_DEV_ORIGINS;
    return raw
      .split(',')
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0);
  }
}
