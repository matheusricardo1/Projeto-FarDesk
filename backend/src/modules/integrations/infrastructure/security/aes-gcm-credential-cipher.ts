import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

import { Injectable } from '@nestjs/common';

import { AppConfigService } from '@shared/infrastructure/config/app-config.service';
import type { CredentialCipher } from '@modules/integrations/application/ports/out/credential-cipher.port';
import type { EncryptedCredential } from '@modules/integrations/domain/value-objects/encrypted-credential.vo';

const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH_BYTES = 32;
const IV_LENGTH_BYTES = 12;

/**
 * AES-256-GCM: IV aleatório por cifragem e `authTag` que detecta
 * adulteração. A chave mestra vem do `AppConfigService` — trocar por KMS é
 * mudar só a origem dela. Falha no boot se a chave não tiver 32 bytes:
 * nunca cifrar segredo de usuário com chave fraca "pra não travar".
 */
@Injectable()
export class AesGcmCredentialCipher implements CredentialCipher {
  private readonly masterKey: Buffer;

  constructor(config: AppConfigService) {
    this.masterKey = AesGcmCredentialCipher.loadMasterKey(config.integrationsMasterKey);
  }

  encrypt(plaintext: string): EncryptedCredential {
    const iv = randomBytes(IV_LENGTH_BYTES);
    const cipher = createCipheriv(ALGORITHM, this.masterKey, iv);
    const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    return {
      ciphertext: ciphertext.toString('base64'),
      iv: iv.toString('base64'),
      authTag: cipher.getAuthTag().toString('base64'),
    };
  }

  decrypt(payload: EncryptedCredential): string {
    const decipher = createDecipheriv(ALGORITHM, this.masterKey, Buffer.from(payload.iv, 'base64'));
    decipher.setAuthTag(Buffer.from(payload.authTag, 'base64'));
    const plaintext = Buffer.concat([
      decipher.update(Buffer.from(payload.ciphertext, 'base64')),
      decipher.final(),
    ]);
    return plaintext.toString('utf8');
  }

  private static loadMasterKey(raw: string): Buffer {
    const key = Buffer.from(raw, 'base64');
    if (key.length !== KEY_LENGTH_BYTES) {
      throw new Error(
        `INTEGRATIONS_MASTER_KEY precisa decodificar pra ${KEY_LENGTH_BYTES} bytes (base64 de uma chave AES-256), recebeu ${key.length}.`,
      );
    }
    return key;
  }
}
