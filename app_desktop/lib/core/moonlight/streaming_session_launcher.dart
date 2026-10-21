import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import '../sunshine/models/sunshine_pair_result.dart';
import '../sunshine/paired_host_store.dart';
import '../sunshine/sunshine_exception.dart';
import '../sunshine/sunshine_host_client.dart';
import '../sunshine/sunshine_identity.dart';
import '../sunshine/sunshine_pairing_client.dart';
import 'moonlight_client.dart';

/// Junta as duas metades que faltavam pro `MoonlightClient.connect()` virar
/// um stream de verdade: o pareamento GameStream (`SunshinePairingClient`,
/// hoje sem nenhum chamador no app) e o launch handshake do Sunshine
/// (`SunshineHostClient.launchApp`). Reaproveita um host já pareado via
/// [PairedHostStore]; quando não há pareamento salvo, [selfPairViaAdmin]
/// permite confirmar o PIN automaticamente (hoje só usado pra testar contra
/// o Sunshine desta própria máquina — ver [HostAgentPairingService] pro
/// equivalente do lado host).
class StreamingSessionLauncher {
  StreamingSessionLauncher({
    required this.identity,
    required this.pairedHostStore,
    required this.moonlightClient,
  });

  final SunshineIdentity identity;
  final PairedHostStore pairedHostStore;
  final MoonlightClient moonlightClient;

  /// Devolve um `SunshineHostClient` pronto pro [deviceId] — reaproveitando
  /// um certificado já pareado e salvo, ou pareando agora (se
  /// [selfPairViaAdmin] for passado) e salvando o resultado pra próxima vez.
  Future<SunshineHostClient> ensurePaired({
    required String deviceId,
    required String host,
    int httpsPort = 47984,
    Future<bool> Function(String pin)? selfPairViaAdmin,
    Future<void> Function(String pin)? onPairingStarted,
  }) async {
    final cached = await pairedHostStore.load(deviceId);
    if (cached != null) {
      return SunshineHostClient(
        identity: identity,
        host: cached.host,
        pinnedServerCertDer: cached.serverCertDer,
        httpsPort: cached.httpsPort,
      );
    }

    if (selfPairViaAdmin == null && onPairingStarted == null) {
      throw const SunshineException(
        'Este dispositivo ainda não foi pareado (protocolo GameStream) — nenhum certificado salvo.',
      );
    }

    final pin = _generatePin();
    final pairingClient = SunshinePairingClient(identity: identity, host: host, httpsPort: httpsPort);
    // Limpa qualquer pareamento pendente/travado de uma tentativa anterior
    // (ver doc de cancelAnyPendingPairing) antes de começar este — senão o
    // lado admin pode casar com a entrada ERRADA (PIN de outra tentativa) e
    // falhar com pinWrong mesmo com tudo certo desta vez.
    await pairingClient.cancelAnyPendingPairing();
    debugPrint('[StreamingSessionLauncher] iniciando pareamento com $host, PIN=$pin');
    final pairFuture = pairingClient.pair(pin: pin).then((outcome) {
      debugPrint('[StreamingSessionLauncher] pair() resolveu: ${outcome.result}');
      return outcome;
    }).catchError((Object error) {
      debugPrint('[StreamingSessionLauncher] pair() lançou erro: $error');
      throw error;
    });

    final accepted = selfPairViaAdmin == null
        ? await _requestRemotePairing(onPairingStarted!, pin, pairFuture)
        : await selfPairViaAdmin(pin);
    debugPrint('[StreamingSessionLauncher] selfPairViaAdmin retornou: $accepted');
    if (!accepted) {
      // Se a confirmação do PIN falhou, o motivo real normalmente está no
      // próprio handshake de pareamento (pair()) — espera um pouco mais por
      // ele pra expor o erro de verdade em vez de um genérico.
      try {
        final outcome = await pairFuture.timeout(const Duration(seconds: 2));
        throw SunshineException(
          'PIN não confirmado a tempo no host (pareamento terminou como: ${outcome.result.name}).',
        );
      } on SunshineException {
        rethrow;
      } catch (error) {
        throw SunshineException('PIN não confirmado a tempo no host. Erro do pareamento: $error');
      }

    }

    final outcome = await pairFuture;
    final serverCertDer = outcome.serverCertDer;
    if (outcome.result != SunshinePairResult.paired || serverCertDer == null) {
      throw SunshineException('Pareamento falhou (${outcome.result.name}).');
    }

    await pairedHostStore.save(
      deviceId,
      PairedHostRecord(host: host, httpsPort: httpsPort, serverCertDer: serverCertDer),
    );

    return SunshineHostClient(identity: identity, host: host, pinnedServerCertDer: serverCertDer, httpsPort: httpsPort);
  }

  Future<bool> _requestRemotePairing(
    Future<void> Function(String pin) onPairingStarted,
    String pin,
    Future<dynamic> pairFuture,
  ) async {
    await onPairingStarted(pin);
    try {
      await pairFuture;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Abre a sessão no host (`/launch`) e conecta o `MoonlightClient` nativo
  /// com os parâmetros que ele devolveu.
  Future<void> launchAndConnect({
    required SunshineHostClient hostClient,
    required String appId,
    int width = 1920,
    int height = 1080,
    int fps = 60,
    int bitrateKbps = 20000,
  }) async {
    final session = await hostClient.launchApp(appId: appId, width: width, height: height, fps: fps);

    await moonlightClient.connect(MoonlightConnectionConfig(
      host: hostClient.host,
      sessionUrl: session.sessionUrl,
      remoteInputKey: Uint8List.fromList(session.riKey),
      remoteInputIv: _ivFromRiKeyId(session.riKeyId),
      width: width,
      height: height,
      fps: fps,
      bitrateKbps: bitrateKbps,
    ));
  }

  String _generatePin() {
    final random = Random.secure();
    return List.generate(4, (_) => random.nextInt(10)).join();
  }

  /// moonlight-common-c lê os 4 primeiros bytes de `remoteInputAesIv` como o
  /// `riKeyId` em big-endian (ver `AudioStream.c`/`InputStream.c`) — o
  /// restante fica zerado. Precisa ser exatamente este layout, senão o host
  /// rejeita o stream de input/áudio criptografado.
  Uint8List _ivFromRiKeyId(int riKeyId) {
    final iv = Uint8List(16);
    final view = ByteData(4)..setUint32(0, riKeyId, Endian.big);
    iv.setRange(0, 4, view.buffer.asUint8List());
    return iv;
  }
}
