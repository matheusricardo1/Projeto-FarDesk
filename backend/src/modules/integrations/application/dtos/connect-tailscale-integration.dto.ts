import { IsNotEmpty, IsString } from 'class-validator';

/** Corpo da requisição, validado pelo `ValidationPipe` global. */
export class ConnectTailscaleIntegrationDto {
  /** Gerado em Settings → Keys → API access tokens no painel do Tailscale. */
  @IsString()
  @IsNotEmpty()
  apiAccessToken!: string;
}

/** Entrada do caso de uso: o corpo + quem está conectando. */
export interface ConnectTailscaleIntegrationCommand {
  ownerId: string;
  apiAccessToken: string;
}
