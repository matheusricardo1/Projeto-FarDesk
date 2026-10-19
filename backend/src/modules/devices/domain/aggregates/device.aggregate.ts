import { AggregateRoot } from '@shared/domain/base/aggregate-root.base';
import { DeviceSessionEndedEvent } from '@modules/devices/domain/events/device-session-ended.event';
import { DeviceSessionStartedEvent } from '@modules/devices/domain/events/device-session-started.event';
import { DeviceWakeRequestedEvent } from '@modules/devices/domain/events/device-wake-requested.event';
import { DeviceNotAvailableException } from '@modules/devices/domain/exceptions/device-not-available.exception';
import { DeviceNotHibernatingException } from '@modules/devices/domain/exceptions/device-not-hibernating.exception';
import { DeviceId } from '@modules/devices/domain/value-objects/device-id.vo';
import type { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';
import { DeviceStatus } from '@modules/devices/domain/value-objects/device-status.vo';

/**
 * Heartbeat adaptativo do panorama: host ocioso reporta 1x/min (barato no
 * serverless); com alguém conectado, 2x/seg.
 */
const IDLE_HEARTBEAT_INTERVAL_SECONDS = 60;
const ACTIVE_HEARTBEAT_INTERVAL_SECONDS = 2;

export interface DeviceProps {
  id: DeviceId;
  ownerId: string;
  name: string;
  platform: DevicePlatform;
  status: DeviceStatus;
  lastHeartbeatAt: Date | null;
  activeViewerCount: number;
}

/**
 * Toda transição de status passa por um método daqui — impossível colocar o
 * agregado num estado inválido (ex: "InUse" com zero espectadores).
 */
export class Device extends AggregateRoot<DeviceId> {
  private props: DeviceProps;

  private constructor(props: DeviceProps) {
    super(props.id);
    this.props = props;
  }

  static create(props: { ownerId: string; name: string; platform: DevicePlatform; id?: DeviceId }): Device {
    return new Device({
      id: props.id ?? DeviceId.create(),
      ownerId: props.ownerId,
      name: props.name,
      platform: props.platform,
      status: DeviceStatus.Offline,
      lastHeartbeatAt: null,
      activeViewerCount: 0,
    });
  }

  /** Reidratação vinda da persistência — não dispara eventos. */
  static reconstruct(props: DeviceProps): Device {
    return new Device(props);
  }

  get ownerId(): string {
    return this.props.ownerId;
  }

  get name(): string {
    return this.props.name;
  }

  get platform(): DevicePlatform {
    return this.props.platform;
  }

  get status(): DeviceStatus {
    return this.props.status;
  }

  get lastHeartbeatAt(): Date | null {
    return this.props.lastHeartbeatAt;
  }

  get activeViewerCount(): number {
    return this.props.activeViewerCount;
  }

  nextHeartbeatIntervalSeconds(): number {
    return this.props.activeViewerCount > 0
      ? ACTIVE_HEARTBEAT_INTERVAL_SECONDS
      : IDLE_HEARTBEAT_INTERVAL_SECONDS;
  }

  /**
   * Offline/Hibernando viram Online — é assim que um `requestWake` se resolve
   * de verdade: só quando o host volta a reportar, nunca otimisticamente.
   */
  recordHeartbeat(now: Date): void {
    this.props.lastHeartbeatAt = now;
    if (this.props.status === DeviceStatus.Offline || this.props.status === DeviceStatus.Hibernating) {
      this.props.status = DeviceStatus.Online;
    }
  }

  markOffline(): void {
    this.props.status = DeviceStatus.Offline;
    this.props.activeViewerCount = 0;
  }

  startSession(): void {
    if (this.props.status !== DeviceStatus.Online) {
      throw new DeviceNotAvailableException(this.id.value, this.props.status);
    }
    this.props.activeViewerCount += 1;
    this.props.status = DeviceStatus.InUse;
    this.addDomainEvent(new DeviceSessionStartedEvent(this.id.value, this.props.ownerId));
  }

  endSession(): void {
    this.props.activeViewerCount = Math.max(0, this.props.activeViewerCount - 1);
    if (this.props.activeViewerCount === 0 && this.props.status === DeviceStatus.InUse) {
      this.props.status = DeviceStatus.Online;
    }
    this.addDomainEvent(new DeviceSessionEndedEvent(this.id.value, this.props.ownerId));
  }

  /** Só valida e anuncia o pedido — o status muda quando o heartbeat voltar. */
  requestWake(): void {
    if (this.props.status !== DeviceStatus.Hibernating) {
      throw new DeviceNotHibernatingException(this.id.value, this.props.status);
    }
    this.addDomainEvent(new DeviceWakeRequestedEvent(this.id.value, this.props.ownerId));
  }

  toSnapshot(): Readonly<DeviceProps> {
    return { ...this.props };
  }
}
