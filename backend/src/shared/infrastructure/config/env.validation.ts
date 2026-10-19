import 'reflect-metadata';

import { plainToInstance } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min, MinLength, validateSync } from 'class-validator';

export enum NodeEnv {
  Development = 'development',
  Test = 'test',
  Production = 'production',
}

/** Tudo que o backend lê do ambiente, validado uma vez no boot — se algo obrigatório faltar, o processo não sobe. */
export class EnvironmentVariables {
  @IsEnum(NodeEnv)
  @IsOptional()
  NODE_ENV: NodeEnv = NodeEnv.Development;

  @IsInt()
  @Min(1)
  @Max(65535)
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  @MinLength(16, {
    message: 'AUTH_JWT_SECRET precisa ter pelo menos 16 caracteres — use `openssl rand -base64 32`.',
  })
  AUTH_JWT_SECRET!: string;

  @IsString()
  @MinLength(16, {
    message: 'INTEGRATIONS_MASTER_KEY precisa decodificar pra 32 bytes — use `openssl rand -base64 32`.',
  })
  INTEGRATIONS_MASTER_KEY!: string;

  /** Opcionais: o resto do backend sobe sem eles; só o login com Google depende. */
  @IsString()
  @IsOptional()
  GOOGLE_CLIENT_ID?: string;

  @IsString()
  @IsOptional()
  GOOGLE_CLIENT_SECRET?: string;

  @IsString()
  @IsOptional()
  GOOGLE_REDIRECT_URI?: string;

  /** CSV de origens permitidas pro CORS. */
  @IsString()
  @IsOptional()
  ALLOWED_ORIGINS?: string;
}

export function validateEnvironment(config: Record<string, unknown>): EnvironmentVariables {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, { enableImplicitConversion: true });
  const errors = validateSync(validatedConfig, { skipMissingProperties: false });

  if (errors.length > 0) {
    const details = errors.map((error) => Object.values(error.constraints ?? {}).join('; ')).join('\n');
    throw new Error(`Configuração de ambiente inválida:\n${details}`);
  }

  return validatedConfig;
}
