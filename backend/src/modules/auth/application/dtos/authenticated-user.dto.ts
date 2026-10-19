/** Quem está fazendo a requisição — contrato que os outros contextos consomem. */
export interface AuthenticatedUser {
  readonly userId: string;
}
