import 'dart:typed_data';

import 'package:app_desktop/core/sunshine/sunshine_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SunshineCrypto', () {
    test('AES-ECB: decrypt desfaz exatamente o que encrypt fez', () {
      final key = SunshineCrypto.randomBytes(16);
      final plaintext = SunshineCrypto.randomBytes(16);

      final roundTrip = SunshineCrypto.aesEcbDecrypt(SunshineCrypto.aesEcbEncrypt(plaintext, key), key);

      expect(roundTrip, equals(plaintext));
    });

    test('deriveAesKey é determinística — mesmo salt+pin sempre dá a mesma chave', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final first = SunshineCrypto.deriveAesKey(salt, '1234');
      final second = SunshineCrypto.deriveAesKey(salt, '1234');

      expect(first, equals(second));
      expect(first.length, 16); // AES-128
    });

    test('deriveAesKey muda se o PIN mudar', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));

      final a = SunshineCrypto.deriveAesKey(salt, '1234');
      final b = SunshineCrypto.deriveAesKey(salt, '4321');

      expect(a, isNot(equals(b)));
    });

    test('encrypt arredonda dados menores que um bloco preenchendo com zeros', () {
      final key = SunshineCrypto.randomBytes(16);
      final shortData = Uint8List.fromList([1, 2, 3]);

      final encrypted = SunshineCrypto.aesEcbEncrypt(shortData, key);

      expect(encrypted.length, 16);
    });

    test('concat junta os bytes na ordem certa', () {
      final result = SunshineCrypto.concat([
        Uint8List.fromList([1, 2]),
        Uint8List.fromList([3]),
        Uint8List.fromList([4, 5]),
      ]);

      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('bytesEqual compara conteúdo, não identidade, e rejeita tamanhos diferentes', () {
      expect(SunshineCrypto.bytesEqual(Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2, 3])), isTrue);
      expect(SunshineCrypto.bytesEqual(Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2, 4])), isFalse);
      expect(SunshineCrypto.bytesEqual(Uint8List.fromList([1, 2]), Uint8List.fromList([1, 2, 3])), isFalse);
    });
  });
}
