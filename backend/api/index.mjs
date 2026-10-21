import { NestFactory } from '@nestjs/core';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/shared/infrastructure/http/configure-app.js';

let appPromise;

async function getHttpHandler() {
  if (!appPromise) {
    appPromise = (async () => {
      const app = await NestFactory.create(AppModule);
      configureApp(app);
      await app.init();
      return app.getHttpAdapter().getInstance();
    })();
  }
  return appPromise;
}

export default async function handler(request, response) {
  const httpHandler = await getHttpHandler();
  return httpHandler(request, response);
}
