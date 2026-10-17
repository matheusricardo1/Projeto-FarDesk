/// Modelo declarativo de configurações. Cada campo é descrito uma vez (chave,
/// rótulo, tipo, padrão) e a UI renderiza a partir disso — adicionar uma
/// configuração nova é só acrescentar uma entrada no schema.
library;

/// De onde a configuração vale: o app como cliente (lado Moonlight) ou esta
/// máquina como host (lado Sunshine).
enum SettingsScope { client, host }

sealed class SettingDefinition {
  const SettingDefinition({required this.key, required this.label, this.description});

  /// Identificador estável usado na persistência. No escopo host, é a chave
  /// do `sunshine.conf`.
  final String key;
  final String label;
  final String? description;
}

/// Configuração que guarda um valor.
sealed class ValueSetting<T extends Object> extends SettingDefinition {
  const ValueSetting({required super.key, required super.label, super.description});

  T get defaultValue;
}

final class ToggleSetting extends ValueSetting<bool> {
  const ToggleSetting({required super.key, required super.label, super.description, required this.defaultValue});

  @override
  final bool defaultValue;
}

class SettingOption {
  const SettingOption(this.value, this.label);
  final String value;
  final String label;
}

final class ChoiceSetting extends ValueSetting<String> {
  const ChoiceSetting({
    required super.key,
    required super.label,
    super.description,
    required this.options,
    required this.defaultValue,
  });

  final List<SettingOption> options;

  @override
  final String defaultValue;
}

final class TextSetting extends ValueSetting<String> {
  const TextSetting({required super.key, required super.label, super.description, this.defaultValue = '', this.hint});

  @override
  final String defaultValue;
  final String? hint;
}

enum ReadOnlyKind { file, display }

/// Valor exibido mas não editado inline (caminho de arquivo, ID de tela) —
/// a edição real vai por seletor de arquivo / lista de telas detectadas.
final class ReadOnlySetting extends ValueSetting<String> {
  const ReadOnlySetting({
    required super.key,
    required super.label,
    super.description,
    required this.defaultValue,
    this.kind = ReadOnlyKind.file,
  });

  @override
  final String defaultValue;
  final ReadOnlyKind kind;
}

/// Configuração que abre um fluxo próprio (editor de comandos, opções
/// avançadas de tela) em vez de guardar um valor simples.
final class ActionSetting extends SettingDefinition {
  const ActionSetting({required super.key, required super.label, super.description, required this.actionLabel});

  final String actionLabel;
}

sealed class SettingsBlock {
  const SettingsBlock();
}

final class SettingsGroup extends SettingsBlock {
  const SettingsGroup({required this.title, this.subtitle, required this.items});

  final String title;
  final String? subtitle;
  final List<SettingDefinition> items;
}

final class SettingsNotice extends SettingsBlock {
  const SettingsNotice(this.text);
  final String text;
}

final class SettingsTable extends SettingsBlock {
  const SettingsTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

/// Página ainda sem especificação (ex: encoders NVENC/QuickSync/AMF).
final class SettingsPlaceholder extends SettingsBlock {
  const SettingsPlaceholder(this.text);
  final String text;
}

class SettingsPage {
  const SettingsPage({
    required this.id,
    required this.label,
    required this.scope,
    required this.blocks,
    this.isSubpage = false,
  });

  final String id;
  final String label;
  final SettingsScope scope;
  final List<SettingsBlock> blocks;

  /// Aparece indentada na navegação, abaixo da página anterior.
  final bool isSubpage;
}
