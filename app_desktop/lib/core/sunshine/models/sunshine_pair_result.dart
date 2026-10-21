import 'dart:typed_data';

/// Espelha `PairingManager.PairState` do Moonlight de referência.
enum SunshinePairResult {
  paired,
  pinWrong,
  failed,

  /// Outro pareamento já está em andamento nesse host — GFE/Sunshine só
  /// aceita uma sessão de pareamento pendente por vez.
  alreadyInProgress,
}

/// Resultado completo de [SunshinePairingClient.pair] — o estado sozinho não
/// basta porque, quando dá certo, quem chamou precisa guardar o certificado
/// do host (fixado/pinned) pra toda chamada futura via `SunshineHostClient`.
class SunshinePairOutcome {
  const SunshinePairOutcome(this.result, {this.serverCertDer});

  final SunshinePairResult result;

  /// Certificado (DER) do host, só presente quando [result] é
  /// [SunshinePairResult.paired].
  final Uint8List? serverCertDer;
}
