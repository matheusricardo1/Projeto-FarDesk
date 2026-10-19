import type { DeviceOwnerQueryDto } from '@modules/pairing/application/dtos/device-owner-query.dto';

export interface PairingRequestActionDto extends DeviceOwnerQueryDto {
  requestId: string;
}

export interface FailPairingRequestDto extends PairingRequestActionDto {
  reason: string;
}
