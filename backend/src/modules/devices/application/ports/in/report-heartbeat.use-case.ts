import type { UseCase } from '@shared/application/ports/use-case.port';
import type { Result } from '@shared/domain/types/result';
import type { DeviceAccessException } from '@modules/devices/domain/services/device-ownership.domain-service';
import type { HeartbeatResponseDto } from '@modules/devices/application/dtos/heartbeat-response.dto';
import type { ReportHeartbeatDto } from '@modules/devices/application/dtos/report-heartbeat.dto';

export const REPORT_HEARTBEAT_USE_CASE = Symbol('REPORT_HEARTBEAT_USE_CASE');

/** Chamado periodicamente pelo agente do host — sustenta o status online/offline e o heartbeat adaptativo. */
export type ReportHeartbeatUseCase = UseCase<
  ReportHeartbeatDto,
  Result<HeartbeatResponseDto, DeviceAccessException>
>;
