import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

class DevicesViewModel extends ChangeNotifier {
  DevicesViewModel(this._repository);

  final DeviceRepository _repository;

  List<Device> _devices = const [];
  String _query = '';
  bool _loading = false;
  Object? _loadError;
  Object? _actionError;
  final Set<String> _pending = {};
  Timer? _heartbeatTimer;

  /// Só chamado pelo `AppShell` quando `HostActivationViewModel` confirma
  /// que este PC está de fato pronto como host (`HostActivationStatus.ready`)
  /// — heartbeat é "estou disponível pra host", não "a tela de dispositivos
  /// está aberta". Repetir a chamada com o timer já armado não faz nada.
  void startHeartbeat() {
    _heartbeatTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_repository.heartbeatThisDevice()),
    );
  }

  /// Contraparte de [startHeartbeat] — chamada quando o host deixa de estar
  /// pronto (preparando de novo, erro, ou a pessoa desativou "usar este PC
  /// como host"). Não derruba o status no backend sozinho: só para de
  /// renovar o heartbeat, e o próprio backend decai pra offline na leitura
  /// depois de ficar tempo demais sem notícia (`Device.effectiveStatus`).
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  bool get isLoading => _loading;
  bool get hasDevices => _devices.isNotEmpty;
  Object? get loadError => _loadError;
  Object? get actionError => _actionError;
  String get query => _query;

  /// Esconde dispositivos offline — por enquanto é como lidamos com um
  /// registro duplicado da mesma máquina (ex: identidade local gerada em
  /// dev e de novo em produção): o fantasma para de receber heartbeat, o
  /// backend decai o status dele pra offline (`Device.effectiveStatus`), e
  /// ele simplesmente some da lista em vez de aparecer ao lado do real.
  /// "Este PC" nunca é escondido por isso — é sempre mostrado (preparando,
  /// pronto ou não) pra sempre dar pra usá-lo/configurá-lo como host.
  List<Device> get visibleDevices {
    final query = _query.trim().toLowerCase();
    return _devices
        .where((d) => d.isCurrentDevice || d.status != DeviceStatus.offline)
        .where((d) => query.isEmpty || d.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  /// Se há uma ação (conectar/acordar) em andamento pra esse dispositivo.
  bool isPending(String deviceId) => _pending.contains(deviceId);

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();

    // Best-effort: se o registro falhar (ex: offline), ainda tentamos
    // listar — só não vai aparecer um card marcado como "este dispositivo"
    // até o próximo `load()` bem-sucedido. Heartbeat é decisão do `AppShell`
    // (ver `startHeartbeat`), não daqui — carregar a lista não é o mesmo
    // que estar disponível como host.
    await _repository.registerThisDevice();

    switch (await _repository.fetchDevices()) {
      case Ok(:final value):
        _devices = value;
      case Failure(:final error):
        _loadError = error;
    }

    _loading = false;
    notifyListeners();
  }

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    notifyListeners();
  }

  Future<Result<void>> connect(Device device) =>
      _runAction(device.id, () => _repository.connect(device.id));

  Future<Result<Device>> wake(Device device) => _runAction(device.id, () async {
    final result = await _repository.wake(device.id);
    if (result case Ok(:final value)) _replace(value);
    return result;
  });

  Future<Result<T>> _runAction<T>(
    String deviceId,
    Future<Result<T>> Function() action,
  ) async {
    if (_pending.contains(deviceId))
      return Failure(StateError('Ação já em andamento para $deviceId.'));
    _pending.add(deviceId);
    _actionError = null;
    notifyListeners();

    try {
      final result = await action();
      if (result case Failure(:final error)) _actionError = error;
      return result;
    } finally {
      _pending.remove(deviceId);
      notifyListeners();
    }
  }

  void _replace(Device updated) {
    _devices = [for (final d in _devices) d.id == updated.id ? updated : d];
  }
}
