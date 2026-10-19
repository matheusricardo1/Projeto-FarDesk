import type { Result } from '@shared/domain/types/result';

export const TAILSCALE_GATEWAY = Symbol('TAILSCALE_GATEWAY');

export interface TailscaleOAuthCredential {
  readonly clientId: string;
  readonly clientSecret: string;
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

/** Sempre a tailnet do próprio usuário (OAuth client dele) — o FarDesk nunca tem tailnet própria. */
export interface TailscaleGateway {
  /** Falha = credencial inválida ou revogada. */
  exchangeForAccessToken(credential: TailscaleOAuthCredential): Promise<Result<string, Error>>;
  /** É daqui que vem o IP/hostname pra rotear o Moonlight até um host. */
  listDevices(accessToken: string): Promise<Result<TailscaleDevice[], Error>>;
  /** Auth key sob demanda pro agente de um host novo entrar na tailnet sem interação manual. */
  createAuthKey(accessToken: string, options: TailscaleAuthKeyOptions): Promise<Result<string, Error>>;
}
