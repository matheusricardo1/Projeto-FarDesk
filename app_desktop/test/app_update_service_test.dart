import 'dart:convert';

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
}
