import 'dart:convert';
import 'dart:io';

import 'package:app_desktop/core/update/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('detects a newer GitHub release installer', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'tag_name': 'v1.0.3',
          'html_url': 'https://github.com/matheusricardo1/Projeto-FarDesk/releases/tag/v1.0.3',
          'assets': [
            {
              'name': 'FarDesk-Setup.exe',
              'browser_download_url': 'https://example.test/FarDesk-Setup.exe',
            },
          ],
        }),
        200,
      );
    });
    final service = AppUpdateService(currentVersion: '1.0.2', client: client);

    final update = await service.checkForUpdate();

    expect(update?.version, '1.0.3');
    expect(update?.installerUrl, 'https://example.test/FarDesk-Setup.exe');
    service.dispose();
  });

  test('does not offer an older or equal release', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'tag_name': 'v1.0.2',
          'html_url': 'https://example.test/release',
          'assets': [
            {
              'name': 'FarDesk-Setup.exe',
              'browser_download_url': 'https://example.test/FarDesk-Setup.exe',
            },
          ],
        }),
        200,
      );
    });
    final service = AppUpdateService(currentVersion: '1.0.2', client: client);

    expect(await service.checkForUpdate(), isNull);
    service.dispose();
  });

  test('downloadInstaller rejects a truncated download and cleans up its temp dir', () async {
    final client = MockClient.streaming((request, bodyStream) async {
      // Anuncia 100 bytes mas só manda 10 — conexão caindo no meio.
      return http.StreamedResponse(Stream.value(List.filled(10, 1)), 200, contentLength: 100);
    });
    final service = AppUpdateService(currentVersion: '1.0.2', client: client);
    final update = const AppUpdateInfo(
      version: '1.0.3',
      releaseUrl: 'https://example.test/release',
      installerUrl: 'https://example.test/FarDesk-Setup.exe',
    );

    final before = _staleUpdateDirs().length;
    await expectLater(service.downloadInstaller(update), throwsA(isA<HttpException>()));
    expect(_staleUpdateDirs().length, before, reason: 'não deve deixar pasta temporária pra trás');
    service.dispose();
  });

  test('cleanupStaleDownloads apaga pastas fardesk-update-* e ignora o resto', () async {
    final stale = await Directory.systemTemp.createTemp('fardesk-update-');
    await File('${stale.path}\\FarDesk-Setup.exe').writeAsBytes([1, 2, 3]);
    final unrelated = await Directory.systemTemp.createTemp('not-fardesk-');

    await AppUpdateService.cleanupStaleDownloads();

    expect(await stale.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
    await unrelated.delete(recursive: true);
  });
}

List<String> _staleUpdateDirs() => Directory.systemTemp
    .listSync()
    .whereType<Directory>()
    .map((d) => d.path)
    .where((p) => p.contains('fardesk-update-'))
    .toList();
