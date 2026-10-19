import { ValidationPipe } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';
import helmet from 'helmet';

import { AppConfigService } from '@shared/infrastructure/config/app-config.service';

/**
 * Configuração de borda da aplicação, aplicada igual em `main.ts` e nos
 * testes de integração — o e2e exercita o mesmo app que vai pra produção.
 */
export function configureApp(app: INestApplication): void {
  const config = app.get(AppConfigService);

  app.use(helmet());
  app.enableCors({
    origin: config.allowedOrigins.length > 0 ? config.allowedOrigins : false,
    credentials: true,
  });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
}
