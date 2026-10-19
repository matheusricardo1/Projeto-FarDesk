import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';

import type { CreatePairingRequestCommand } from '@modules/pairing/application/dtos/create-pairing-request.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import { PairingRequestMapper } from '@modules/pairing/application/mappers/pairing-request.mapper';
import { DEVICE_LOOKUP_GATEWAY } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import type { DeviceLookupGateway } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import type { CreatePairingRequestUseCase } from '@modules/pairing/application/ports/in/create-pairing-request.use-case';
import { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import { DeviceNotAccessibleException } from '@modules/pairing/domain/exceptions/device-not-accessible.exception';
import { PAIRING_REQUEST_REPOSITORY } from '@modules/pairing/domain/repositories/pairing-request.repository';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';

@Injectable()
export class CreatePairingRequestUseCaseImpl implements CreatePairingRequestUseCase {
  constructor(
    @Inject(PAIRING_REQUEST_REPOSITORY) private readonly requests: PairingRequestRepository,
    @Inject(DEVICE_LOOKUP_GATEWAY) private readonly devices: DeviceLookupGateway,
  ) {}

  async execute(
    input: CreatePairingRequestCommand,
  ): Promise<Result<PairingRequestResponseDto, DeviceNotAccessibleException>> {
    const owned = await this.devices.isOwnedByAccount(input.deviceId, input.ownerId);
    if (!owned) return Result.err(new DeviceNotAccessibleException(input.deviceId));

    const request = PairingRequest.request({
      deviceId: input.deviceId,
      ownerId: input.ownerId,
      pin: input.pin,
      now: new Date(),
    });
    await this.requests.save(request);

    return Result.ok(PairingRequestMapper.toResponse(request));
  }
}
