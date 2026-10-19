import { Controller, Get, HttpCode, HttpStatus, Inject, Param, Post } from '@nestjs/common';

import type { AuthenticatedUser } from '@modules/auth/application/dtos/authenticated-user.dto';
import { CurrentUser } from '@modules/auth/infrastructure/http/current-user.decorator';
import type { DeviceResponseDto } from '@modules/devices/application/dtos/device-response.dto';
import type { HeartbeatResponseDto } from '@modules/devices/application/dtos/heartbeat-response.dto';
import { END_SESSION_USE_CASE } from '@modules/devices/application/ports/in/end-session.use-case';
import type { EndSessionUseCase } from '@modules/devices/application/ports/in/end-session.use-case';
import { LIST_DEVICES_USE_CASE } from '@modules/devices/application/ports/in/list-devices.use-case';
import type { ListDevicesUseCase } from '@modules/devices/application/ports/in/list-devices.use-case';
import { REPORT_HEARTBEAT_USE_CASE } from '@modules/devices/application/ports/in/report-heartbeat.use-case';
import type { ReportHeartbeatUseCase } from '@modules/devices/application/ports/in/report-heartbeat.use-case';
import { REQUEST_WAKE_USE_CASE } from '@modules/devices/application/ports/in/request-wake.use-case';
import type { RequestWakeUseCase } from '@modules/devices/application/ports/in/request-wake.use-case';
import { START_SESSION_USE_CASE } from '@modules/devices/application/ports/in/start-session.use-case';
import type { StartSessionUseCase } from '@modules/devices/application/ports/in/start-session.use-case';

/**
 * Adaptador de entrada: depende só das portas de entrada (interfaces), nunca
 * das implementações. Autenticação vem do `JwtAuthGuard` global.
 */
@Controller('devices')
export class DevicesController {
  constructor(
    @Inject(LIST_DEVICES_USE_CASE) private readonly listDevices: ListDevicesUseCase,
    @Inject(START_SESSION_USE_CASE) private readonly startSession: StartSessionUseCase,
    @Inject(END_SESSION_USE_CASE) private readonly endSession: EndSessionUseCase,
    @Inject(REQUEST_WAKE_USE_CASE) private readonly requestWake: RequestWakeUseCase,
    @Inject(REPORT_HEARTBEAT_USE_CASE) private readonly reportHeartbeat: ReportHeartbeatUseCase,
  ) {}

  @Get()
  async list(@CurrentUser() user: AuthenticatedUser): Promise<DeviceResponseDto[]> {
    const result = await this.listDevices.execute({ ownerId: user.userId });
    return result.value;
  }

  @Post(':id/connect')
  @HttpCode(HttpStatus.OK)
  async connect(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser): Promise<DeviceResponseDto> {
    const result = await this.startSession.execute({ deviceId: id, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }

  @Post(':id/disconnect')
  @HttpCode(HttpStatus.OK)
  async disconnect(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DeviceResponseDto> {
    const result = await this.endSession.execute({ deviceId: id, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }

  @Post(':id/wake')
  @HttpCode(HttpStatus.OK)
  async wake(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser): Promise<DeviceResponseDto> {
    const result = await this.requestWake.execute({ deviceId: id, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }

  /** Chamado pelo agente instalado no host, não pelo app cliente. */
  @Post(':id/heartbeat')
  @HttpCode(HttpStatus.OK)
  async heartbeat(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<HeartbeatResponseDto> {
    const result = await this.reportHeartbeat.execute({ deviceId: id, ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }
}
