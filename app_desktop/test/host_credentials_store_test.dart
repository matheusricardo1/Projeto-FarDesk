import 'dart:io';

import 'package:app_desktop/core/host_agent/host_credentials_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostCredentialsStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('host_credentials_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('gera usuário fixo e senha aleatória não vazia na primeira vez', () async {
      final credentials = await HostCredentialsStore(directory: tempDir).load();

      expect(credentials.username, hostAdminUsername);
      expect(credentials.password, isNotEmpty);
    });

    test('marca generatedThisRun só quando a credencial é gerada agora', () async {
      final store = HostCredentialsStore(directory: tempDir);
      await store.load();
      expect(store.generatedThisRun, isTrue);

      final second = HostCredentialsStore(directory: tempDir);
      await second.load();
      expect(second.generatedThisRun, isFalse);
    });

    test('carrega a mesma credencial salva em vez de gerar uma nova', () async {
      final store = HostCredentialsStore(directory: tempDir);

      final first = await store.load();
      final second = await HostCredentialsStore(directory: tempDir).load();

      expect(second.username, first.username);
      expect(second.password, first.password);
    });
  });
}
