import { Matches } from 'class-validator';

/** Validado pelo `ValidationPipe` global. O PIN é gerado pelo cliente — o backend só carrega. */
export class CreatePairingRequestDto {
  @Matches(/^\d{4}$/, { message: 'pin precisa ter exatamente 4 dígitos.' })
  pin!: string;
}

export interface CreatePairingRequestCommand {
  deviceId: string;
  ownerId: string;
  pin: string;
}
