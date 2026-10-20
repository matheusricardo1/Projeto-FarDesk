import { Module } from '@nestjs/common';

import { END_SESSION_USE_CASE } from '@modules/devices/application/ports/in/end-session.use-case';
import { LIST_DEVICES_USE_CASE } from '@modules/devices/application/ports/in/list-devices.use-case';
import { REGISTER_DEVICE_USE_CASE } from '@modules/devices/application/ports/in/register-device.use-case';
import { GET_HOST_CREDENTIAL_USE_CASE } from '@modules/devices/application/ports/in/get-host-credential.use-case';
import { SAVE_HOST_CREDENTIAL_USE_CASE } from '@modules/devices/application/ports/in/save-host-credential.use-case';
import { REPORT_HEARTBEAT_USE_CASE } from '@modules/devices/application/ports/in/report-heartbeat.use-case';
import { REQUEST_WAKE_USE_CASE } from '@modules/devices/application/ports/in/request-wake.use-case';
import { START_SESSION_USE_CASE } from '@modules/devices/application/ports/in/start-session.use-case';
import { EndSessionUseCaseImpl } from '@modules/devices/application/use-cases/end-session.use-case.impl';
import { ListDevicesUseCaseImpl } from '@modules/devices/application/use-cases/list-devices.use-case.impl';
import { RegisterDeviceUseCaseImpl } from '@modules/devices/application/use-cases/register-device.use-case.impl';
import { GetHostCredentialUseCaseImpl } from '@modules/devices/application/use-cases/get-host-credential.use-case.impl';
import { SaveHostCredentialUseCaseImpl } from '@modules/devices/application/use-cases/save-host-credential.use-case.impl';
import { CREDENTIAL_CIPHER } from '@shared/application/ports/credential-cipher.port';
import { AesGcmCredentialCipher } from '@shared/infrastructure/security/aes-gcm-credential-cipher';
import { ReportHeartbeatUseCaseImpl } from '@modules/devices/application/use-cases/report-heartbeat.use-case.impl';
import { RequestWakeUseCaseImpl } from '@modules/devices/application/use-cases/request-wake.use-case.impl';
import { StartSessionUseCaseImpl } from '@modules/devices/application/use-cases/start-session.use-case.impl';
import { DEVICE_REPOSITORY } from '@modules/devices/domain/repositories/device.repository';
import { DevicesController } from '@modules/devices/infrastructure/http/devices.controller';
import { DeviceEventsListener } from '@modules/devices/infrastructure/messaging/device-events.listener';
import { PrismaDeviceRepository } from '@modules/devices/infrastructure/persistence/device.repository.prisma';

/** Composition root do contexto: o único lugar que liga cada porta à sua implementação. */
@Module({
  controllers: [DevicesController],
  providers: [
    { provide: LIST_DEVICES_USE_CASE, useClass: ListDevicesUseCaseImpl },
    { provide: START_SESSION_USE_CASE, useClass: StartSessionUseCaseImpl },
    { provide: END_SESSION_USE_CASE, useClass: EndSessionUseCaseImpl },
    { provide: REQUEST_WAKE_USE_CASE, useClass: RequestWakeUseCaseImpl },
    { provide: REPORT_HEARTBEAT_USE_CASE, useClass: ReportHeartbeatUseCaseImpl },
    { provide: REGISTER_DEVICE_USE_CASE, useClass: RegisterDeviceUseCaseImpl },
    { provide: GET_HOST_CREDENTIAL_USE_CASE, useClass: GetHostCredentialUseCaseImpl },
    { provide: SAVE_HOST_CREDENTIAL_USE_CASE, useClass: SaveHostCredentialUseCaseImpl },
    { provide: CREDENTIAL_CIPHER, useClass: AesGcmCredentialCipher },
    { provide: DEVICE_REPOSITORY, useClass: PrismaDeviceRepository },
    DeviceEventsListener,
  ],
  // `pairing` precisa consultar ownership de dispositivo — ver `DeviceRepositoryLookupGateway`.
  exports: [DEVICE_REPOSITORY],
})
export class DevicesModule {}
