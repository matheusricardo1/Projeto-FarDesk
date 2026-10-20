import { Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';
import type {
  TailscaleAuthKeyOptions,
  TailscaleDevice,
  TailscaleGateway,
} from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

const TAILSCALE_API_BASE = 'https://api.tailscale.com/api/v2';

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
export class TailscaleApiGateway implements TailscaleGateway {
  /**
   * Não existe endpoint dedicado de "whoami" na API do Tailscale — validar
   * é só chamar algo de leitura barato (a própria lista de devices) e ver
   * se o token é aceito.
   */
  async validateAccessToken(apiAccessToken: string): Promise<Result<void, Error>> {
    const result = await this.listDevices(apiAccessToken);
    return result.isErr ? Result.err(result.error) : Result.ok(undefined);
  }

  async listDevices(apiAccessToken: string): Promise<Result<TailscaleDevice[], Error>> {
    try {
      const response = await fetch(`${TAILSCALE_API_BASE}/tailnet/-/devices`, {
        headers: { Authorization: `Bearer ${apiAccessToken}` },
      });
      if (!response.ok) {
        return Result.err(new Error(`Tailscale recusou o token (HTTP ${response.status}).`));
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

  async createAuthKey(apiAccessToken: string, options: TailscaleAuthKeyOptions): Promise<Result<string, Error>> {
    try {
      const response = await fetch(`${TAILSCALE_API_BASE}/tailnet/-/keys`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiAccessToken}` },
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
