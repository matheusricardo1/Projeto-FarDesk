import type { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';

export interface PairingRequestResponseDto {
  id: string;
  deviceId: string;
  pin: string;
  status: PairingRequestStatus;
  expiresAt: string;
  failureReason: string | null;
}
