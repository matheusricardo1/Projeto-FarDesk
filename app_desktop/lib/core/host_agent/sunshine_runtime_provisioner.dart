import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Garante que os arquivos portáteis do Sunshine estão em disco, baixando a
/// release oficial da LizardByte na primeira vez que alguém usa este PC
/// como host. Nada disso é commitado no repositório — o binário (~36MB) só
/// existe na máquina de quem realmente precisa dele.
///
/// O zip oficial já vem com uma pasta `Sunshine/` dentro — por isso
/// `ensureInstalled()` devolve `<diretório de extração>/Sunshine`, não o
/// diretório de extração em si.
class SunshineRuntimeProvisioner {
  SunshineRuntimeProvisioner({
    this.releaseAssetUrl =
        'https://github.com/LizardByte/Sunshine/releases/latest/download/Sunshine-Windows-AMD64-lite.zip',
    Directory? extractionParentDirectory,
  }) : _extractionParentOverride = extractionParentDirectory;

  /// URL fixa pro asset mais recente — o GitHub redireciona sozinho pra
  /// última release publicada, sem precisar consultar a API antes.
  final String releaseAssetUrl;
  final Directory? _extractionParentOverride;

  /// Devolve o diretório `Sunshine/` já pronto pra uso — baixa e extrai só
  /// se ainda não existir (identificado pela presença de `tools/sunshinesvc.exe`).
  Future<Directory> ensureInstalled() async {
    final parent = await _extractionParent();
    final installDir = Directory('${parent.path}\\Sunshine');
    final marker = File('${installDir.path}\\tools\\sunshinesvc.exe');
    if (await marker.exists()) return installDir;

    await parent.create(recursive: true);
    final zipFile = File('${parent.path}\\sunshine-lite.zip');
    await _download(zipFile);
    await _extract(zipFile, parent);
    await zipFile.delete();

    if (!await marker.exists()) {
      throw const SunshineProvisioningException(
        'O zip do Sunshine foi extraído, mas tools/sunshinesvc.exe não apareceu — '
        'o formato do pacote oficial pode ter mudado.',
      );
    }
    return installDir;
  }

  /// Igual `ensureInstalled()`, mas nunca baixa nada — `null` se os
  /// arquivos ainda não existem nesta máquina. É o que dá pra chamar no
  /// startup do app sem o risco de disparar um download de 36MB só por
  /// verificar o estado.
  Future<Directory?> installedDirectoryIfPresent() async {
    final parent = await _extractionParent();
    final installDir = Directory('${parent.path}\\Sunshine');
    final marker = File('${installDir.path}\\tools\\sunshinesvc.exe');
    return await marker.exists() ? installDir : null;
  }

  Future<void> _download(File destination) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(releaseAssetUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw SunshineProvisioningException('Falha ao baixar o Sunshine (HTTP ${response.statusCode}).');
      }
      final sink = destination.openWrite();
      await response.stream.pipe(sink);
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<void> _extract(File zipFile, Directory destination) async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      "Expand-Archive -Path '${zipFile.path}' -DestinationPath '${destination.path}' -Force",
    ]);
    if (result.exitCode != 0) {
      throw SunshineProvisioningException('Falha ao extrair o Sunshine: ${result.stderr}');
    }
  }

  Future<Directory> _extractionParent() async {
    final override = _extractionParentOverride;
    if (override != null) return override;
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}\\host');
  }
}

class SunshineProvisioningException implements Exception {
  const SunshineProvisioningException(this.message);

  final String message;

  @override
  String toString() => 'SunshineProvisioningException: $message';
}
