import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../domain/setting.dart';
import '../domain/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository);

  final SettingsRepository _repository;

  final Map<SettingsScope, Map<String, Object>> _values = {};
  bool _loading = false;
  Object? _error;

  bool get isLoading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    for (final scope in SettingsScope.values) {
      switch (await _repository.load(scope)) {
        case Ok(:final value):
          _values[scope] = Map.of(value);
        case Failure(:final error):
          _error = error;
      }
    }

    _loading = false;
    notifyListeners();
  }

  /// Valor atual da configuração — o salvo, ou o padrão do schema.
  T valueOf<T extends Object>(SettingsScope scope, ValueSetting<T> setting) {
    final stored = _values[scope]?[setting.key];
    return stored is T ? stored : setting.defaultValue;
  }

  /// Atualização otimista: a UI reflete na hora e a persistência roda em
  /// seguida. Se falhar, o erro fica exposto em [error].
  Future<void> update<T extends Object>(SettingsScope scope, ValueSetting<T> setting, T value) async {
    (_values[scope] ??= {})[setting.key] = value;
    notifyListeners();

    if (await _repository.save(scope, setting.key, value) case Failure(:final error)) {
      _error = error;
      notifyListeners();
    }
  }
}
