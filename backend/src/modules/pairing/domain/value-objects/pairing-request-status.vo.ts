export enum PairingRequestStatus {
  /** Criado pelo cliente, esperando o agente do host pegar o PIN. */
  Pending = 'pending',

  /** O agente confirmou que já submeteu o PIN pro Sunshine local. */
  Delivered = 'delivered',

  /** O cliente terminou o handshake HTTPS com sucesso. */
  Completed = 'completed',

  Failed = 'failed',
  Expired = 'expired',
}
