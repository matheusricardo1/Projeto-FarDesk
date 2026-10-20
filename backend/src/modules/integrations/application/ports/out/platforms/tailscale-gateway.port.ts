import type { Result } from '@shared/domain/types/result';

export const TAILSCALE_GATEWAY = Symbol('TAILSCALE_GATEWAY');

/**
 * Um único token (gerado em Settings → Keys → API access tokens no painel
 * do Tailscale), não um par client ID/secret — OAuth clients não existem
 * em tailnets no plano Personal/Free, só em planos pagos. O token já é o
 * Bearer usado direto na API, sem troca nenhuma.
 */
export interface TailscaleApiCredential {
  readonly apiAccessToken: string;
}

export interface TailscaleDevice {
  readonly id: string;
  readonly name: string;
  readonly hostname: string;
  readonly addresses: readonly string[];
  readonly online: boolean;
}

export interface TailscaleAuthKeyOptions {
  readonly reusable: boolean;
  readonly ephemeral: boolean;
  readonly tags?: readonly string[];
}

/** Sempre a tailnet do próprio usuário (token dele) — o FarDesk nunca tem tailnet própria. */
export interface TailscaleGateway {
  /** Falha = token inválido, expirado ou revogado. */
  validateAccessToken(apiAccessToken: string): Promise<Result<void, Error>>;
  /** É daqui que vem o IP/hostname pra rotear o Moonlight até um host. */
  listDevices(apiAccessToken: string): Promise<Result<TailscaleDevice[], Error>>;
  /** Auth key sob demanda pro agente de um host novo entrar na tailnet sem interação manual. */
  createAuthKey(apiAccessToken: string, options: TailscaleAuthKeyOptions): Promise<Result<string, Error>>;
}
