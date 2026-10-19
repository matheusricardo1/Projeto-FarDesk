import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Primitivas criptográficas do protocolo de pareamento do Sunshine/Moonlight
/// (GameStream). Nada daqui é específico do FarDesk — é o mesmo algoritmo
/// usado por qualquer cliente Moonlight: AES-128-ECB (sem padding real, os
/// blocos são arredondados pra 16 bytes com zeros) e SHA-256, nunca CBC.
///
/// Puro Dart — sem dependência de Flutter, pra poder ser compartilhado com o
/// app mobile no futuro, igual o resto de `core/`.
class SunshineCrypto {
  const SunshineCrypto._();

  /// 16 bytes aleatórios usados como sal na derivação da chave AES a partir do PIN.
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// Chave AES-128 derivada de `sha256(salt + pin)[0:16]` — é exatamente o que
  /// `crypto::gen_aes_key` faz no lado do host (Sunshine), então tem que bater
  /// byte a byte ou o host nunca vai aceitar nosso desafio.
  static Uint8List deriveAesKey(Uint8List salt, String pin) {
    final saltedPin = Uint8List.fromList([...salt, ...pin.codeUnits]);
    return Uint8List.fromList(sha256(saltedPin).sublist(0, 16));
  }

  static Uint8List sha256(Uint8List data) {
    final digest = SHA256Digest();
    return digest.process(data);
  }

  /// AES-128-ECB, sem padding — os dados são arredondados pra múltiplo de 16
  /// bytes preenchendo com zeros (não é PKCS7). É assim que o Sunshine espera;
  /// ECB porque o GameStream protocol original (NVIDIA) foi desenhado assim,
  /// bem antes do Sunshine existir, e ninguém pode mudar sem quebrar
  /// compatibilidade com todo cliente Moonlight já publicado.
  static Uint8List aesEcbEncrypt(Uint8List data, Uint8List key) {
    final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
    return _processBlocks(cipher, _padToBlockSize(data));
  }

  static Uint8List aesEcbDecrypt(Uint8List data, Uint8List key) {
    final cipher = ECBBlockCipher(AESEngine())..init(false, KeyParameter(key));
    return _processBlocks(cipher, _padToBlockSize(data));
  }

  static Uint8List _padToBlockSize(Uint8List data, {int blockSize = 16}) {
    final roundedSize = ((data.length + blockSize - 1) ~/ blockSize) * blockSize;
    if (roundedSize == data.length) return data;
    final padded = Uint8List(roundedSize)..setRange(0, data.length, data);
    return padded;
  }

  static Uint8List _processBlocks(BlockCipher cipher, Uint8List data) {
    final output = Uint8List(data.length);
    for (var offset = 0; offset < data.length; offset += cipher.blockSize) {
      cipher.processBlock(data, offset, output, offset);
    }
    return output;
  }

  static Uint8List concat(List<Uint8List> parts) {
    final totalLength = parts.fold<int>(0, (sum, part) => sum + part.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return result;
  }

  static bool bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
