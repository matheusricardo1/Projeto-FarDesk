import { Global, Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';

import { DOMAIN_EVENT_PUBLISHER } from '@shared/application/ports/event-publisher.port';
import { EventEmitterDomainEventPublisher } from '@shared/infrastructure/messaging/event-emitter.publisher';

@Global()
@Module({
  imports: [EventEmitterModule.forRoot({ wildcard: false, verboseMemoryLeak: true })],
  providers: [{ provide: DOMAIN_EVENT_PUBLISHER, useClass: EventEmitterDomainEventPublisher }],
  exports: [DOMAIN_EVENT_PUBLISHER],
})
export class MessagingModule {}
