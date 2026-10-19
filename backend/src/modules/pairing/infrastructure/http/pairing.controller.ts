import { Body, Controller, Get, HttpCode, HttpStatus, Inject, Param, Post } from '@nestjs/common';
import { IsString, MinLength } from 'class-validator';

import type { AuthenticatedUser } from '@modules/auth/application/dtos/authenticated-user.dto';
import { CurrentUser } from '@modules/auth/infrastructure/http/current-user.decorator';
import { CreatePairingRequestDto } from '@modules/pairing/application/dtos/create-pairing-request.dto';
import type { PairingRequestResponseDto } from '@modules/pairing/application/dtos/pairing-request-response.dto';
import { ACK_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/ack-pairing-request.use-case';
import type { AckPairingRequestUseCase } from '@modules/pairing/application/ports/in/ack-pairing-request.use-case';
import { COMPLETE_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/complete-pairing-request.use-case';
import type { CompletePairingRequestUseCase } from '@modules/pairing/application/ports/in/complete-pairing-request.use-case';
import { CREATE_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/create-pairing-request.use-case';
import type { CreatePairingRequestUseCase } from '@modules/pairing/application/ports/in/create-pairing-request.use-case';
import { FAIL_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/fail-pairing-request.use-case';
import type { FailPairingRequestUseCase } from '@modules/pairing/application/ports/in/fail-pairing-request.use-case';
import { GET_PENDING_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/get-pending-pairing-request.use-case';
import type { GetPendingPairingRequestUseCase } from '@modules/pairing/application/ports/in/get-pending-pairing-request.use-case';

class FailPairingRequestBody {
  @IsString()
  @MinLength(1)
  reason!: string;
}

/**
 * Envelope em vez de devolver `PairingRequestResponseDto | null` cru — um
 * controller do Nest que retorna `null` faz o Express mandar corpo vazio,
 * não o JSON literal `null`, e aí o cliente recebe `{}` em vez de "nada
 * pendente". Com o envelope, `request` sempre existe como chave, mesmo que `null`.
 */
interface PendingPairingRequestResponseDto {
  request: PairingRequestResponseDto | null;
}

/**
 * Autenticação é o `JwtAuthGuard` global — tanto o app cliente quanto o
 * (futuro) agente do host se autenticam como a mesma conta FarDesk, então
 * não precisa de guard separado aqui: ownership de `deviceId` é quem decide
 * se cada chamada é aceita (ver `DeviceLookupGateway`).
 */
@Controller('devices/:deviceId/pairing-requests')
export class PairingController {
  constructor(
    @Inject(CREATE_PAIRING_REQUEST_USE_CASE) private readonly createRequest: CreatePairingRequestUseCase,
    @Inject(GET_PENDING_PAIRING_REQUEST_USE_CASE)
    private readonly getPending: GetPendingPairingRequestUseCase,
    @Inject(ACK_PAIRING_REQUEST_USE_CASE) private readonly ackRequest: AckPairingRequestUseCase,
    @Inject(COMPLETE_PAIRING_REQUEST_USE_CASE)
    private readonly completeRequest: CompletePairingRequestUseCase,
    @Inject(FAIL_PAIRING_REQUEST_USE_CASE) private readonly failRequest: FailPairingRequestUseCase,
  ) {}

  /** O app cliente chama isto antes de iniciar o handshake HTTPS direto com o host. */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Param('deviceId') deviceId: string,
    @Body() body: CreatePairingRequestDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PairingRequestResponseDto> {
    const result = await this.createRequest.execute({ deviceId, ownerId: user.userId, pin: body.pin });
    if (result.isErr) throw result.error;
    return result.value;
  }

  /** O agente do host faz polling nisto enquanto espera um pareamento. */
  @Get('pending')
  async pending(
    @Param('deviceId') deviceId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PendingPairingRequestResponseDto> {
    const result = await this.getPending.execute({ deviceId, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return { request: result.value };
  }

  /** O agente chama isto depois de submeter o PIN pro Sunshine local. */
  @Post(':requestId/ack')
  @HttpCode(HttpStatus.OK)
  async ack(
    @Param('deviceId') deviceId: string,
    @Param('requestId') requestId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PairingRequestResponseDto> {
    const result = await this.ackRequest.execute({ deviceId, requestId, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }

  /** O app cliente chama isto quando o handshake HTTPS com o host termina com sucesso. */
  @Post(':requestId/complete')
  @HttpCode(HttpStatus.OK)
  async complete(
    @Param('deviceId') deviceId: string,
    @Param('requestId') requestId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PairingRequestResponseDto> {
    const result = await this.completeRequest.execute({ deviceId, requestId, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }

  /** Cliente ou agente chamam isto quando o pareamento falha de algum jeito. */
  @Post(':requestId/fail')
  @HttpCode(HttpStatus.OK)
  async fail(
    @Param('deviceId') deviceId: string,
    @Param('requestId') requestId: string,
    @Body() body: FailPairingRequestBody,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PairingRequestResponseDto> {
    const result = await this.failRequest.execute({
      deviceId,
      requestId,
      ownerId: user.userId,
      reason: body.reason,
    });
    if (result.isErr) throw result.error;
    return result.value;
  }
}
