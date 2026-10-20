import 'dart:async';

import '../sunshine/sunshine_pairing_client.dart' show sunshineClientDeviceName;
import 'pairing_api_client.dart';
import 'sunshine_admin_client.dart';

/// O lado do host do fluxo de pareamento sem fricção: fica de olho no
/// backend do FarDesk e, assim que aparece um PIN esperando pra este
/// dispositivo, submete ele pro Sunshine local sozinho — é isso que
/// substitui a pessoa digitando o PIN na UI do Sunshine.
///
/// Fluxo de um ciclo (`_tick`):
/// 1. Pergunta pro backend: tem `PairingRequest` pendente pra esse device?
/// 2. Se tem, chama `ensureHostRunning` — é só agora que o Sunshine liga de
///    verdade (`HostActivation.ensureRunning`), nunca antes de alguém
///    realmente tentar conectar.
/// 3. Pergunta pro Sunshine local: quais pareamentos estão esperando PIN?
/// 4. Acha, entre esses, o que tem o nosso nome de dispositivo
///    (`sunshineClientDeviceName` — o cliente já iniciou o handshake HTTPS
///    real nesse meio tempo, é isso que faz esse pareamento aparecer aqui).
/// 5. Submete o PIN pro Sunshine com o `pairing_id` certo.
/// 6. Confirma (`ack`) ou reporta falha (`fail`) de volta pro backend.
///
/// Não lida com o caso de duas pessoas tentando parear o mesmo host ao
/// mesmo tempo (pegaria o primeiro pareamento pendente com o nome certo,
/// sem diferenciar por IP) — cenário raro o bastante pra não valer a
/// complexidade agora; documentado aqui de propósito, não esquecido.
class HostAgentPairingService {
  HostAgentPairingService({
    required this.deviceId,
    required this.pairingApi,
    required this.sunshineAdmin,
    this.ensureHostRunning,
    this.pollInterval = const Duration(seconds: 1),
    this.onError,
  });

  final String deviceId;
  final PairingApiClient pairingApi;
  final SunshineAdminClient sunshineAdmin;
  final Duration pollInterval;

  /// Liga o Sunshine (e configura credencial, na primeira vez) — só chamado
  /// quando um `PairingRequest` pendente de verdade aparece, nunca em todo
  /// ciclo de poll. `null` (padrão em teste) significa "já está no ar",
  /// nada a fazer; em produção é `HostActivation().ensureRunning`.
  final Future<void> Function()? ensureHostRunning;

  /// Erros de um ciclo não derrubam o loop — só são reportados aqui, se alguém quiser logar/observar.
  final void Function(Object error)? onError;

  Timer? _timer;
  bool _ticking = false;

  bool get isRunning => _timer != null;

  void start() {
    if (isRunning) return;
    _timer = Timer.periodic(pollInterval, (_) => runPairingCycle());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Um ciclo completo do loop. Público pra poder ser testado isoladamente,
  /// sem esperar o `Timer.periodic` de verdade — `start()`/`stop()` continuam
  /// sendo o jeito normal de usar isto fora de teste.
  Future<void> runPairingCycle() async {
    // Evita sobrepor ciclos se uma chamada HTTP demorar mais que o pollInterval.
    if (_ticking) return;
    _ticking = true;
    try {
      await _runOnce();
    } catch (error) {
      onError?.call(error);
    } finally {
      _ticking = false;
    }
  }

  Future<void> _runOnce() async {
    final pending = await pairingApi.fetchPending(deviceId);
    if (pending == null || pending.status != 'pending') return;

    // Só liga o Sunshine quando existe de fato alguém tentando conectar —
    // nunca em background por antecedência.
    await ensureHostRunning?.call();

    final localPairings = await sunshineAdmin.listPendingPairings();
    final match = localPairings.where((pairing) => pairing.deviceName == sunshineClientDeviceName).firstOrNull;
    if (match == null) {
      // O cliente ainda não chegou no Sunshine local — tenta de novo no próximo ciclo.
      return;
    }

    final accepted = await sunshineAdmin.submitPin(
      pairingId: match.pairingId,
      pin: pending.pin,
      clientName: sunshineClientDeviceName,
    );

    if (accepted) {
      await pairingApi.ack(deviceId, pending.id);
    } else {
      await pairingApi.fail(deviceId, pending.id, 'Sunshine recusou o PIN.');
    }
  }
}
