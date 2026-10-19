/// Resposta de `GET /serverinfo` — identidade e estado atual do host.
class SunshineServerInfo {
  const SunshineServerInfo({
    required this.hostname,
    required this.appVersion,
    required this.uniqueId,
    required this.httpsPort,
    required this.externalPort,
    required this.isPaired,
    required this.currentGameId,
    required this.state,
  });

  final String hostname;
  final String appVersion;

  /// `uniqueid` do HOST (não confundir com o `uniqueId` do nosso `SunshineIdentity`, que é do cliente).
  final String uniqueId;
  final int httpsPort;
  final int externalPort;
  final bool isPaired;

  /// `0` quando nenhum app está rodando.
  final int currentGameId;

  /// `SUNSHINE_SERVER_FREE` ou `SUNSHINE_SERVER_BUSY`.
  final String state;

  bool get isBusy => currentGameId > 0;
}
