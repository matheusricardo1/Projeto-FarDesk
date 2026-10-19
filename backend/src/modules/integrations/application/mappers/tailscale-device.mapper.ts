import type { TailscaleDeviceResponseDto } from '@modules/integrations/application/dtos/tailscale-device-response.dto';
import type { TailscaleDevice } from '@modules/integrations/application/ports/out/platforms/tailscale-gateway.port';

export class TailscaleDeviceMapper {
  static toResponse(device: TailscaleDevice): TailscaleDeviceResponseDto {
    return {
      id: device.id,
      name: device.name,
      hostname: device.hostname,
      addresses: [...device.addresses],
      online: device.online,
    };
  }
}
