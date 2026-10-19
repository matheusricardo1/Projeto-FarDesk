export interface CompleteGoogleLoginDto {
  /** O `state` devolvido pelo Google no callback — é o id da `LoginSession`. */
  loginSessionId: string;
  code: string;
}
