import type { DeviceActionDto } from '@modules/devices/application/dtos/device-action.dto';

export interface ReportHeartbeatDto extends DeviceActionDto {
  at?: Date;
}
