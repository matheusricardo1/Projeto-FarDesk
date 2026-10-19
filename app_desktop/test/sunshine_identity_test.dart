import 'dart:io';

import 'package:app_desktop/core/sunshine/sunshine_identity.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SunshineIdentityStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sunshine_identity_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('gera um certificado autoassinado válido e uma chave privada correspondente', () async {
      final identity = await SunshineIdentityStore(directory: tempDir).load();

      expect(identity.uniqueId, isNotEmpty);
      expect(identity.certificatePem, contains('BEGIN CERTIFICATE'));

      // O certificado tem que ter sido assinado pela chave privada que guardamos junto.
      final certData = X509Utils.x509CertificateFromPem(identity.certificatePem);
      expect(certData.signatureAlgorithmReadableName, contains('RSA'));
    });

    test('carrega a mesma identidade salva em vez de gerar uma nova', () async {
      final store = SunshineIdentityStore(directory: tempDir);

      final first = await store.load();
      final second = await SunshineIdentityStore(directory: tempDir).load();

      expect(second.uniqueId, first.uniqueId);
      expect(second.certificatePem, first.certificatePem);
    });

    test('certificatePemHex é o PEM codificado em hex, não o DER cru', () async {
      final identity = await SunshineIdentityStore(directory: tempDir).load();

      final decoded = String.fromCharCodes(
        List.generate(
          identity.certificatePemHex.length ~/ 2,
          (i) => int.parse(identity.certificatePemHex.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );

      expect(decoded, identity.certificatePem);
    });
  });
}
