import { Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import type {
  TailscaleAuthKeyOptions,
  TailscaleDevice,
  TailscaleGateway,
  TailscaleOAuthCredential,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

const TAILSCALE_API_BASE = 'https://api.tailscale.com/api/v2';

interface TailscaleTokenResponse {
  access_token: string;
}

interface TailscaleDeviceApiResponse {
  devices: Array<{
    id: string;
    name: string;
    hostname: string;
    addresses: string[];
    online?: boolean;
  }>;
}

interface TailscaleCreateKeyApiResponse {
  key: string;
}

/** Adaptador real da API do Tailscale. Usa sempre a tailnet "-" (a default do token = a do próprio usuário). */
@Injectable()
export class TailscaleOAuthGateway implements TailscaleGateway {
  async exchangeForAccessToken(credential: TailscaleOAuthCredential): Promise<Result<string, Error>> {
    try {
      const basic = Buffer.from(`${credential.clientId}:${credential.clientSecret}`).toString('base64');
      const response = await fetch(`${TAILSCALE_API_BASE}/oauth/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', Authorization: `Basic ${basic}` },
        body: 'grant_type=client_credentials',
      });
      if (!response.ok) {
        return Result.err(new Error(`Tailscale recusou as credenciais (HTTP ${response.status}).`));
      }
      const body = (await response.json()) as TailscaleTokenResponse;
      return Result.ok(body.access_token);
    } catch (error) {
      return Result.err(
        error instanceof Error ? error : new Error('Falha desconhecida ao autenticar no Tailscale.'),
      );
    }
  }

  async listDevices(accessToken: string): Promise<Result<TailscaleDevice[], Error>> {
    try {
      const response = await fetch(`${TAILSCALE_API_BASE}/tailnet/-/devices`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (!response.ok) {
        return Result.err(new Error(`Falha ao listar dispositivos do Tailscale (HTTP ${response.status}).`));
      }
      const body = (await response.json()) as TailscaleDeviceApiResponse;
      return Result.ok(
        body.devices.map((device) => ({
          id: device.id,
          name: device.name,
          hostname: device.hostname,
          addresses: device.addresses,
          online: device.online ?? false,
        })),
      );
    } catch (error) {
      return Result.err(
        error instanceof Error ? error : new Error('Falha desconhecida ao listar dispositivos.'),
      );
    }
  }

  async createAuthKey(accessToken: string, options: TailscaleAuthKeyOptions): Promise<Result<string, Error>> {
    try {
      const response = await fetch(`${TAILSCALE_API_BASE}/tailnet/-/keys`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` },
        body: JSON.stringify({
          capabilities: {
            devices: {
              create: { reusable: options.reusable, ephemeral: options.ephemeral, tags: options.tags ?? [] },
            },
          },
        }),
      });
      if (!response.ok) {
        return Result.err(new Error(`Falha ao gerar auth key no Tailscale (HTTP ${response.status}).`));
      }
      const body = (await response.json()) as TailscaleCreateKeyApiResponse;
      return Result.ok(body.key);
    } catch (error) {
      return Result.err(error instanceof Error ? error : new Error('Falha desconhecida ao gerar auth key.'));
    }
  }
}
