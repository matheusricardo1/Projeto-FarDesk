/** Entrada comum de toda operação sobre um dispositivo específico (conectar, desconectar, acordar). */
export interface DeviceActionDto {
  deviceId: string;
  ownerId: string;
}
