import '../../../core/result.dart';
import '../domain/setting.dart';
import '../domain/settings_repository.dart';

/// Guarda em memória durante a execução — perde tudo ao fechar o app.
class InMemorySettingsRepository implements SettingsRepository {
  final Map<SettingsScope, Map<String, Object>> _store = {};

  @override
  Future<Result<Map<String, Object>>> load(SettingsScope scope) async {
    return Ok(Map.unmodifiable(_store[scope] ?? const {}));
  }

  @override
  Future<Result<void>> save(SettingsScope scope, String key, Object value) async {
    (_store[scope] ??= {})[key] = value;
    return const Ok(null);
  }
}
