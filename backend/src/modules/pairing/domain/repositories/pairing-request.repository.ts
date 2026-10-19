import type { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';

export const PAIRING_REQUEST_REPOSITORY = Symbol('PAIRING_REQUEST_REPOSITORY');

export interface PairingRequestRepository {
  findById(id: string): Promise<PairingRequest | null>;

  /** A mais recente `Pending`/`Delivered` desse dispositivo — não filtra expiração, quem decide isso é o caso de uso. */
  findActiveByDevice(deviceId: string): Promise<PairingRequest | null>;

  save(request: PairingRequest): Promise<void>;
}
