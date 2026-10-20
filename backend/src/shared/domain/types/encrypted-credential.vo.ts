/**
 * Segredo de terceiro já cifrado — a única forma como um segredo (OAuth
 * token, credencial de host local etc.) existe em repouso. Nenhum campo
 * aqui é o segredo em si.
 */
export interface EncryptedCredential {
  readonly ciphertext: string;
  readonly iv: string;
  readonly authTag: string;
}
