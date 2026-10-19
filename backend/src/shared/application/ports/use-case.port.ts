/** Contrato de toda porta de entrada (input port) da aplicação. */
export interface UseCase<Input, Output> {
  execute(input: Input): Promise<Output>;
}
