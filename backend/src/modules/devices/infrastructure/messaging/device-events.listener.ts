import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';

import type { DeviceSessionEndedEvent } from '@modules/devices/domain/events/device-session-ended.event';
import type { DeviceSessionStartedEvent } from '@modules/devices/domain/events/device-session-started.event';
import type { DeviceWakeRequestedEvent } from '@modules/devices/domain/events/device-wake-requested.event';

/** Consumidor dos eventos do contexto — ponto de entrada pra notificação em tempo real, métricas, auditoria. */
@Injectable()
export class DeviceEventsListener {
  private readonly logger = new Logger(DeviceEventsListener.name);

  @OnEvent('device.session.started')
  onSessionStarted(event: DeviceSessionStartedEvent): void {
    this.logger.log(`Sessão iniciada: device=${event.deviceId} owner=${event.ownerId}`);
  }

  @OnEvent('device.session.ended')
  onSessionEnded(event: DeviceSessionEndedEvent): void {
    this.logger.log(`Sessão encerrada: device=${event.deviceId} owner=${event.ownerId}`);
  }

  @OnEvent('device.wake.requested')
  onWakeRequested(event: DeviceWakeRequestedEvent): void {
    this.logger.log(`Wake solicitado: device=${event.deviceId} owner=${event.ownerId}`);
  }
}
