import type { EncryptedCredential } from '@shared/domain/types/encrypted-credential.vo';

export const CREDENTIAL_CIPHER = Symbol('CREDENTIAL_CIPHER');

/** Cifra segredos de terceiro em repouso. Algoritmo e origem da chave mestra são detalhe do adapter. */
export interface CredentialCipher {
  encrypt(plaintext: string): EncryptedCredential;
  decrypt(payload: EncryptedCredential): string;
}
