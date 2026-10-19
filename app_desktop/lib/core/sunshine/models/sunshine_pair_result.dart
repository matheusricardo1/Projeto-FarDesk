/// Espelha `PairingManager.PairState` do Moonlight de referência.
enum SunshinePairResult {
  paired,
  pinWrong,
  failed,

  /// Outro pareamento já está em andamento nesse host — GFE/Sunshine só
  /// aceita uma sessão de pareamento pendente por vez.
  alreadyInProgress,
}
