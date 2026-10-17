import '../../../core/result.dart';
import 'setting.dart';

/// Persistência dos valores de configuração, por escopo. Só guarda o que foi
/// alterado — o padrão vem do schema.
///
/// Implementações reais previstas:
/// - host: lê/escreve o `sunshine.conf` (as chaves do schema já são as dele);
/// - client: preferências locais do app.
abstract interface class SettingsRepository {
  Future<Result<Map<String, Object>>> load(SettingsScope scope);

  Future<Result<void>> save(SettingsScope scope, String key, Object value);
}
