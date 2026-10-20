import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { NotDeviceOwnerException } from '@modules/devices/domain/exceptions/not-device-owner.exception';
import type { HostCredential } from '@modules/devices/application/dtos/host-credential.dto';

export const GET_HOST_CREDENTIAL_USE_CASE = Symbol('GET_HOST_CREDENTIAL_USE_CASE');

export interface GetHostCredentialCommand {
  ownerId: string;
  deviceId: string;
}

export type GetHostCredentialUseCase = UseCase<
  GetHostCredentialCommand,
  Result<HostCredential | null, NotDeviceOwnerException>
>;
