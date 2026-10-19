/// Resultado de `GET /launch` — o suficiente pra abrir a sessão RTSP depois
/// (a troca efetiva de áudio/vídeo ainda não existe no app; isso é o que a
/// prepara). `riKey`/`riKeyId` são os mesmos valores já enviados no launch —
/// guardados aqui porque o RTSP handshake seguinte também precisa deles.
class SunshineLaunchSession {
  const SunshineLaunchSession({required this.sessionUrl, required this.riKey, required this.riKeyId});

  final String sessionUrl;
  final List<int> riKey;
  final int riKeyId;
}
