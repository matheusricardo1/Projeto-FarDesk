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

  bool get isLoading => _loading;
  bool get hasDevices => _devices.isNotEmpty;
  Object? get loadError => _loadError;
  Object? get actionError => _actionError;
  String get query => _query;

  List<Device> get visibleDevices {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _devices;
    return _devices
        .where((d) => d.name.toLowerCase().contains(query))
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
    // até o próximo `load()` bem-sucedido.
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
