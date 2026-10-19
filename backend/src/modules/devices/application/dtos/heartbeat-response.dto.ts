import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';

export interface HeartbeatResponseDto {
  device: DeviceResponseDto;
  /** Em quantos segundos o agente deve mandar o próximo heartbeat. */
  nextHeartbeatIntervalSeconds: number;
}
