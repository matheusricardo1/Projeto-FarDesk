/** Entrada comum de toda consulta/ação restrita a quem é dono do dispositivo. */
export interface DeviceOwnerQueryDto {
  deviceId: string;
  ownerId: string;
}
