import { Global, Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';

import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import { validateEnvironment } from '@shared/infrastructure/config/env.validation';

/**
 * `@Global()` aqui também, não só `isGlobal` no módulo interno do Nest: isso
 * torna o `ConfigService` dele global, mas não o nosso `AppConfigService`.
 */
@Global()
@Module({
  imports: [
    NestConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnvironment,
      envFilePath: ['.env.local', '.env'],
    }),
  ],
  providers: [AppConfigService],
  exports: [AppConfigService],
})
export class AppConfigModule {}
