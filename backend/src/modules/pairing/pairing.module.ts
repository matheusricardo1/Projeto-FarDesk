import { Module } from '@nestjs/common';

import { DevicesModule } from '@modules/devices/devices.module';

import { ACK_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/ack-pairing-request.use-case';
import { COMPLETE_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/complete-pairing-request.use-case';
import { CREATE_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/create-pairing-request.use-case';
import { FAIL_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/fail-pairing-request.use-case';
import { GET_PENDING_PAIRING_REQUEST_USE_CASE } from '@modules/pairing/application/ports/in/get-pending-pairing-request.use-case';
import { DEVICE_LOOKUP_GATEWAY } from '@modules/pairing/application/ports/out/device-lookup.gateway.port';
import { AckPairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/ack-pairing-request.use-case.impl';
import { CompletePairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/complete-pairing-request.use-case.impl';
import { CreatePairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/create-pairing-request.use-case.impl';
import { FailPairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/fail-pairing-request.use-case.impl';
import { GetPendingPairingRequestUseCaseImpl } from '@modules/pairing/application/use-cases/get-pending-pairing-request.use-case.impl';
import { PAIRING_REQUEST_REPOSITORY } from '@modules/pairing/domain/repositories/pairing-request.repository';
import { DeviceRepositoryLookupGateway } from '@modules/pairing/infrastructure/gateways/device-lookup.gateway';
import { PairingController } from '@modules/pairing/infrastructure/http/pairing.controller';
import { PairingEventsListener } from '@modules/pairing/infrastructure/messaging/pairing-events.listener';
import { InMemoryPairingRequestRepository } from '@modules/pairing/infrastructure/persistence/pairing-request.repository.impl';

@Module({
  imports: [DevicesModule],
  controllers: [PairingController],
  providers: [
    { provide: CREATE_PAIRING_REQUEST_USE_CASE, useClass: CreatePairingRequestUseCaseImpl },
    { provide: GET_PENDING_PAIRING_REQUEST_USE_CASE, useClass: GetPendingPairingRequestUseCaseImpl },
    { provide: ACK_PAIRING_REQUEST_USE_CASE, useClass: AckPairingRequestUseCaseImpl },
    { provide: COMPLETE_PAIRING_REQUEST_USE_CASE, useClass: CompletePairingRequestUseCaseImpl },
    { provide: FAIL_PAIRING_REQUEST_USE_CASE, useClass: FailPairingRequestUseCaseImpl },
    { provide: PAIRING_REQUEST_REPOSITORY, useClass: InMemoryPairingRequestRepository },
    { provide: DEVICE_LOOKUP_GATEWAY, useClass: DeviceRepositoryLookupGateway },
    PairingEventsListener,
  ],
})
export class PairingModule {}
