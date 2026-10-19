export const DEVICE_LOOKUP_GATEWAY = Symbol('DEVICE_LOOKUP_GATEWAY');

/**
 * Única porta de saída do contexto — pergunta pro contexto `devices` "esse
 * dispositivo é dessa conta?" sem o domínio/aplicação de `pairing` conhecer
 * nada de `Device`. Quem resolve essa pergunta de verdade (hoje, lendo o
 * repositório de `devices` direto, já que é o mesmo processo) é o adapter
 * em `infrastructure/gateways`.
 */
export interface DeviceLookupGateway {
  isOwnedByAccount(deviceId: string, ownerId: string): Promise<boolean>;
}
