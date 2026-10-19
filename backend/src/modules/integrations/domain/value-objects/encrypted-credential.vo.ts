/**
 * Segredo de provedor já cifrado — a única forma como um segredo de
 * integração existe em repouso. Nenhum campo aqui é o segredo em si.
 */
export interface EncryptedCredential {
  readonly ciphertext: string;
  readonly iv: string;
  readonly authTag: string;
}
