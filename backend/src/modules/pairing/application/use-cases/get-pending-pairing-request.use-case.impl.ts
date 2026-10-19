import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';

import type { DeviceOwnerQueryDto } from '@modules/pairing/application/dtos/device-owner-query.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import { PairingRequestMapper } from '@modules/pairing/application/mappers/pairing-request.mapper';
import { DEVICE_LOOKUP_GATEWAY } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import type { DeviceLookupGateway } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import type { GetPendingPairingRequestUseCase } from '@modules/pairing/application/ports/in/get-pending-pairing-request.use-case';
import { DeviceNotAccessibleException } from '@modules/pairing/domain/exceptions/device-not-accessible.exception';
import { PAIRING_REQUEST_REPOSITORY } from '@modules/pairing/domain/repositories/pairing-request.repository';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';

/** Chamado pelo agente do host, em loop curto, enquanto espera um pareamento acontecer. */
@Injectable()
export class GetPendingPairingRequestUseCaseImpl implements GetPendingPairingRequestUseCase {
  constructor(
    @Inject(PAIRING_REQUEST_REPOSITORY) private readonly requests: PairingRequestRepository,
    @Inject(DEVICE_LOOKUP_GATEWAY) private readonly devices: DeviceLookupGateway,
  ) {}

  async execute(
    input: DeviceOwnerQueryDto,
  ): Promise<Result<PairingRequestResponseDto | null, DeviceNotAccessibleException>> {
    const owned = await this.devices.isOwnedByAccount(input.deviceId, input.ownerId);
    if (!owned) return Result.err(new DeviceNotAccessibleException(input.deviceId));

    const request = await this.requests.findActiveByDevice(input.deviceId);
    if (!request) return Result.ok(null);

    const now = new Date();
    if (request.isExpired(now)) {
      request.expire();
      await this.requests.save(request);
      return Result.ok(null);
    }

    return Result.ok(PairingRequestMapper.toResponse(request));
  }
}
