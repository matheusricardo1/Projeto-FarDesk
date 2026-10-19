import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';

import type { FailPairingRequestDto } from '@modules/pairing/application/dtos/pairing-request-action.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import { PairingRequestMapper } from '@modules/pairing/application/mappers/pairing-request.mapper';
import type { FailPairingRequestUseCase } from '@modules/pairing/application/ports/in/fail-pairing-request.use-case';
import { PairingRequestNotFoundException } from '@modules/pairing/domain/exceptions/pairing-request-not-found.exception';
import { PAIRING_REQUEST_REPOSITORY } from '@modules/pairing/domain/repositories/pairing-request.repository';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';

@Injectable()
export class FailPairingRequestUseCaseImpl implements FailPairingRequestUseCase {
  constructor(@Inject(PAIRING_REQUEST_REPOSITORY) private readonly requests: PairingRequestRepository) {}

  async execute(
    input: FailPairingRequestDto,
  ): Promise<Result<PairingRequestResponseDto, PairingRequestNotFoundException>> {
    const request = await this.requests.findById(input.requestId);
    if (!request || request.deviceId !== input.deviceId || request.ownerId !== input.ownerId) {
      return Result.err(new PairingRequestNotFoundException(input.requestId));
    }

    request.fail(input.reason);
    await this.requests.save(request);
    return Result.ok(PairingRequestMapper.toResponse(request));
  }
}
