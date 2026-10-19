import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { AppModule } from '@app.module';
import { JwtSessionTokenIssuer } from '@modules/auth/infrastructure/security/jwt-session-token-issuer';
import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import { configureApp } from '@shared/infrastructure/http/configure-app';

export interface TestApp {
  app: INestApplication;
  http: () => ReturnType<typeof request>;
  /** Header `Authorization` válido pra uma conta, sem passar pelo login com Google. */
  authHeaderFor: (accountId: string) => string;
}

export async function createTestApp(): Promise<TestApp> {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  const app = moduleRef.createNestApplication();
  configureApp(app);
  await app.init();

  const issuer = new JwtSessionTokenIssuer(app.get(AppConfigService));

  return {
    app,
    http: () => request(app.getHttpServer() as Parameters<typeof request>[0]),
    authHeaderFor: (accountId) => `Bearer ${issuer.issue(accountId).accessToken}`,
  };
}
