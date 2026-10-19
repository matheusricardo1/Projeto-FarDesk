import { Inject, Injectable } from '@nestjs/common';

import { Result } from '@shared/domain/types/result';

import type { PairingRequestActionDto } from '@modules/pairing/application/dtos/pairing-request-action.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import { PairingRequestMapper } from '@modules/pairing/application/mappers/pairing-request.mapper';
import type { CompletePairingRequestUseCase } from '@modules/pairing/application/ports/in/complete-pairing-request.use-case';
import type { PairingRequestActionError } from '@modules/pairing/application/ports/in/ack-pairing-request.use-case';
import { PairingRequestExpiredException } from '@modules/pairing/domain/exceptions/pairing-request-expired.exception';
import { PairingRequestNotFoundException } from '@modules/pairing/domain/exceptions/pairing-request-not-found.exception';
import { PAIRING_REQUEST_REPOSITORY } from '@modules/pairing/domain/repositories/pairing-request.repository';
import type { PairingRequestRepository } from '@modules/pairing/domain/repositories/pairing-request.repository';

@Injectable()
export class CompletePairingRequestUseCaseImpl implements CompletePairingRequestUseCase {
  constructor(@Inject(PAIRING_REQUEST_REPOSITORY) private readonly requests: PairingRequestRepository) {}

  async execute(
    input: PairingRequestActionDto,
  ): Promise<Result<PairingRequestResponseDto, PairingRequestActionError>> {
    const request = await this.requests.findById(input.requestId);
    if (!request || request.deviceId !== input.deviceId || request.ownerId !== input.ownerId) {
      return Result.err(new PairingRequestNotFoundException(input.requestId));
    }

    try {
      request.complete(new Date());
    } catch (error) {
      if (error instanceof PairingRequestExpiredException) return Result.err(error);
      throw error;
    }

    await this.requests.save(request);
    return Result.ok(PairingRequestMapper.toResponse(request));
  }
}
