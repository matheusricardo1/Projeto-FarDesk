import { IsNotEmpty, IsString } from 'class-validator';

/** Corpo da requisição, validado pelo `ValidationPipe` global. */
export class ConnectTailscaleIntegrationDto {
  @IsString()
  @IsNotEmpty()
  clientId!: string;

  @IsString()
  @IsNotEmpty()
  clientSecret!: string;
}

/** Entrada do caso de uso: o corpo + quem está conectando. */
export interface ConnectTailscaleIntegrationCommand {
  ownerId: string;
  clientId: string;
  clientSecret: string;
}
