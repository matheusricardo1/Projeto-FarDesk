import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '@app.module';
import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import { configureApp } from '@shared/infrastructure/http/configure-app';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  configureApp(app);

  const config = app.get(AppConfigService);
  await app.listen(config.port);
  Logger.log(`FarDesk backend rodando em http://localhost:${config.port} (${config.nodeEnv})`, 'Bootstrap');
}

void bootstrap();
