import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.releaseUrl,
    required this.installerUrl,
  });

  final String version;
  final String releaseUrl;
  final String installerUrl;
}

class AppUpdateService {
  AppUpdateService({
    required this.currentVersion,
    http.Client? client,
    this.repository = 'matheusricardo1/Projeto-FarDesk',
  }) : _client = client ?? http.Client();

  final String currentVersion;
  final String repository;
  final http.Client _client;

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/repos/$repository/releases/latest'),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'FarDesk',
        },
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'GitHub Releases respondeu ${response.statusCode}.',
        );
      }

      final release = jsonDecode(response.body);
      if (release is! Map<String, dynamic>) {
        throw const FormatException('Resposta de release inválida.');
      }
      final tag = release['tag_name'];
      final releaseUrl = release['html_url'];
      final assets = release['assets'];
      if (tag is! String || releaseUrl is! String || assets is! List) {
        throw const FormatException('Release sem metadados obrigatórios.');
      }

      final version = _normalizeVersion(tag);
      final installer = assets
          .cast<dynamic>()
          .whereType<Map<String, dynamic>>()
          .firstWhere(
            (asset) =>
                asset['name'] == 'FarDesk-Setup.exe' &&
                asset['browser_download_url'] is String,
            orElse: () => <String, dynamic>{},
          );
      final installerUrl = installer['browser_download_url'];
      if (installerUrl is! String ||
          _compareVersions(version, _normalizeVersion(currentVersion)) <= 0) {
        return null;
      }

      return AppUpdateInfo(
        version: version,
        releaseUrl: releaseUrl,
        installerUrl: installerUrl,
      );
    } on SocketException catch (error, stackTrace) {
      _logCheckFailure(error, stackTrace);
      return null;
    } on HttpException catch (error, stackTrace) {
      _logCheckFailure(error, stackTrace);
      return null;
    } on FormatException catch (error, stackTrace) {
      _logCheckFailure(error, stackTrace);
      return null;
    }
  }

  /// [onProgress] recebe bytes recebidos e bytes totais a cada chunk — o
  /// total vem `-1` quando o servidor não manda `Content-Length`.
  Future<File> downloadInstaller(
    AppUpdateInfo update, {
    void Function(int received, int total)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(update.installerUrl));
    final response = await _client.send(request);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Não foi possível baixar a atualização (${response.statusCode}).',
      );
    }

    final expectedBytes = response.contentLength ?? -1;
    final directory = await Directory.systemTemp.createTemp('fardesk-update-');
    final installer = File('${directory.path}\\FarDesk-Setup.exe');
    final sink = installer.openWrite();
    var received = 0;
    try {
      await response.stream.listen((chunk) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(received, expectedBytes);
      }).asFuture<void>();
    } finally {
      await sink.close();
    }

    // Download truncado (conexão caiu no meio) não deve virar um instalador
    // corrompido rodando silenciosamente — falha explícito e deixa o usuário
    // tentar de novo.
    if (received == 0 || (expectedBytes >= 0 && received != expectedBytes)) {
      await directory.delete(recursive: true);
      throw HttpException(
        'Download incompleto (recebido $received de $expectedBytes bytes). Tente novamente.',
      );
    }
    return installer;
  }

  void dispose() => _client.close();

  static String _normalizeVersion(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
    return normalized.split('+').first.split('-').first;
  }

  static int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map(int.parse).toList();
    final rightParts = right.split('.').map(int.parse).toList();
    for (var index = 0; index < 3; index++) {
      final difference =
          (leftParts.length > index ? leftParts[index] : 0) -
          (rightParts.length > index ? rightParts[index] : 0);
      if (difference != 0) return difference.sign;
    }
    return 0;
  }

  void _logCheckFailure(Object error, StackTrace stackTrace) {
    stderr.writeln(
      '[AppUpdateService] não foi possível verificar atualizações: $error',
    );
    stderr.writeln(stackTrace);
  }
}
