import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import { DevicePlatform } from '@modules/devices/domain/value-objects/device-platform.vo';

/**
 * Corpo da requisição. `deviceId` é gerado e persistido pelo próprio
 * cliente (uma vez por instalação, ver `LocalDeviceIdStore` no app
 * desktop) — nunca pelo backend; é assim que o cliente sabe, entre os
 * devices que `GET /devices` devolve, qual é "este aqui".
 */
export class RegisterDeviceDto {
  @IsString()
  @IsNotEmpty()
  deviceId!: string;

  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;
}

/** Entrada do caso de uso: o corpo + quem está registrando. */
export interface RegisterDeviceCommand {
  ownerId: string;
  deviceId: string;
  name: string;
  platform: DevicePlatform;
}
