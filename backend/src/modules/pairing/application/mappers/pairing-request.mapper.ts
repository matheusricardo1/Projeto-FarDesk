import type { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';

export class PairingRequestMapper {
  static toResponse(request: PairingRequest): PairingRequestResponseDto {
    return {
      id: request.id.value,
      deviceId: request.deviceId,
      pin: request.pin,
      status: request.status,
      expiresAt: request.expiresAt.toISOString(),
      failureReason: request.failureReason,
    };
  }
}
