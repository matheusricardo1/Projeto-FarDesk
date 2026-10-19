import { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import { PairingRequestId } from '@modules/pairing/domain/value-objects/pairing-request-id.vo';
import type { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';

export interface PairingRequestRecord {
  id: string;
  deviceId: string;
  ownerId: string;
  pin: string;
  status: PairingRequestStatus;
  createdAt: string;
  expiresAt: string;
  failureReason: string | null;
}

export class PairingRequestPersistenceMapper {
  static toRecord(request: PairingRequest): PairingRequestRecord {
    const snapshot = request.toSnapshot();
    return {
      id: snapshot.id.value,
      deviceId: snapshot.deviceId,
      ownerId: snapshot.ownerId,
      pin: snapshot.pin,
      status: snapshot.status,
      createdAt: snapshot.createdAt.toISOString(),
      expiresAt: snapshot.expiresAt.toISOString(),
      failureReason: snapshot.failureReason,
    };
  }

  static toDomain(record: PairingRequestRecord): PairingRequest {
    return PairingRequest.reconstruct({
      id: PairingRequestId.create(record.id),
      deviceId: record.deviceId,
      ownerId: record.ownerId,
      pin: record.pin,
      status: record.status,
      createdAt: new Date(record.createdAt),
      expiresAt: new Date(record.expiresAt),
      failureReason: record.failureReason,
    });
  }
}
