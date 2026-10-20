import { randomBytes } from 'node:crypto';

import { AesGcmCredentialCipher } from '@shared/infrastructure/security/aes-gcm-credential-cipher';
import type { AppConfigService } from '@shared/infrastructure/config/app-config.service';

const VALID_KEY = randomBytes(32).toString('base64');

function cipherWith(integrationsMasterKey: string): AesGcmCredentialCipher {
  return new AesGcmCredentialCipher({ integrationsMasterKey } as AppConfigService);
}

describe('AesGcmCredentialCipher', () => {
  it('decifra exatamente o texto que cifrou', () => {
    const cipher = cipherWith(VALID_KEY);

    expect(cipher.decrypt(cipher.encrypt('segredo-super-sensivel'))).toBe('segredo-super-sensivel');
  });

  it('usa um IV diferente a cada chamada — o mesmo texto não produz o mesmo ciphertext', () => {
    const cipher = cipherWith(VALID_KEY);

    const first = cipher.encrypt('mesmo-texto');
    const second = cipher.encrypt('mesmo-texto');

    expect(first.iv).not.toBe(second.iv);
    expect(first.ciphertext).not.toBe(second.ciphertext);
  });

  it('recusa decifrar se o authTag foi adulterado', () => {
    const cipher = cipherWith(VALID_KEY);
    const encrypted = cipher.encrypt('segredo');

    expect(() =>
      cipher.decrypt({ ...encrypted, authTag: Buffer.from('adulterado').toString('base64') }),
    ).toThrow();
  });

  it('não sobe se a chave não decodificar pra 32 bytes', () => {
    expect(() => cipherWith(Buffer.from('chave-curta-demais').toString('base64'))).toThrow(/32 bytes/);
  });
});
