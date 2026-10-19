export enum IntegrationStatus {
  Connected = 'connected',
  Disconnected = 'disconnected',
  /** A credencial existe mas a última tentativa de uso falhou (ex: revogada no provedor). */
  Error = 'error',
}
