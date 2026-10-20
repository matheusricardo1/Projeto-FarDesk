import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import type { HostCredential } from '@modules/devices/application/dtos/host-credential.dto';

export const SAVE_HOST_CREDENTIAL_USE_CASE = Symbol('SAVE_HOST_CREDENTIAL_USE_CASE');

export interface SaveHostCredentialCommand {
  ownerId: string;
  deviceId: string;
  credential: HostCredential;
}

export type SaveHostCredentialUseCase = UseCase<
  SaveHostCredentialCommand,
  Result<void, NotDeviceOwnerException>
>;
