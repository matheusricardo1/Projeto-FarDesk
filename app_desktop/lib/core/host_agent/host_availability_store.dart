import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Preferência "usar este PC como host" — liga por padrão em toda
/// instalação; só grava em disco quando a pessoa explicitamente desliga (ou
/// religa depois de ter desligado). Separada do `SettingsRepository` de
/// propósito: aquele hoje só guarda em memória (ver
/// `InMemorySettingsRepository`) e essa preferência precisa sobreviver a
/// reinícios — senão o PC "esqueceria" de estar disponível como host a
/// cada abertura do app, mesmo o padrão sendo ligado.
class HostAvailabilityStore {
  HostAvailabilityStore({Directory? directory}) : _directoryOverride = directory;

  final Directory? _directoryOverride;
  bool? _cached;

  Future<bool> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final file = await _preferenceFile();
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _cached = json['useAsHost'] as bool? ?? true;
    }
    return _cached = true;
  }

  Future<void> save(bool useAsHost) async {
    final file = await _preferenceFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode({'useAsHost': useAsHost}));
    _cached = useAsHost;
  }

  Future<File> _preferenceFile() async {
    final directory = _directoryOverride ?? await getApplicationSupportDirectory();
    return File('${directory.path}/host_availability.json');
  }
}
