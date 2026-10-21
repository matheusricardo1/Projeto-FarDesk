import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:convert/convert.dart';

import 'sunshine_identity.dart';

/// Monta o `HttpClient` usado em toda chamada HTTPS ao host: apresenta o
/// certificado da nossa [SunshineIdentity] (mTLS — o host exige isso em
/// qualquer coisa além do pareamento) e confia *só* no certificado do host
/// que recebemos durante o pareamento, nunca na cadeia de CAs do sistema —
/// o Sunshine é sempre autoassinado, então validar contra uma CA não faz
/// sentido aqui; o que prova que é o host certo é bater exatamente com o
/// certificado que guardamos.
HttpClient createSunshineHttpClient({required SunshineIdentity identity, Uint8List? pinnedServerCertDer}) {
  final context = SecurityContext(withTrustedRoots: false)
    ..usePrivateKeyBytes(utf8.encode(identity.privateKeyPem))
    ..useCertificateChainBytes(utf8.encode(identity.certificatePem));

  final client = HttpClient(context: context);
  client.badCertificateCallback = (cert, host, port) {
    if (pinnedServerCertDer == null) return false;
    final received = Uint8List.fromList(cert.der);
    if (received.length != pinnedServerCertDer.length) return false;
    for (var i = 0; i < received.length; i++) {
      if (received[i] != pinnedServerCertDer[i]) return false;
    }
    return true;
  };
  return client;
}

/// DER do certificado do host, a partir do PEM recebido em `/pair` — é contra
/// isso que `createSunshineHttpClient` compara toda conexão TLS seguinte.
Uint8List serverCertificateDer(String serverCertificatePem) => CryptoUtils.getBytesFromPEMString(serverCertificatePem);

/// Bytes da assinatura de um certificado, a partir do campo `signature` do
/// basic_utils — que vem em hex e com o primeiro byte do BIT STRING do ASN.1
/// ("bits não usados", sempre 0x00) ainda grudado. Os hashes do pareamento
/// usam só a assinatura em si (256 bytes pra RSA-2048, igual ao
/// `X509Certificate.getSignature()` do Java usado pelo Moonlight); com o
/// byte extra, todo hash sai diferente do host e o pareamento acaba em
/// `pinWrong`.
Uint8List certificateSignatureFromHex(String signatureHex) {
  final bytes = Uint8List.fromList(hex.decode(signatureHex));
  if (bytes.isNotEmpty && bytes.length.isOdd && bytes.first == 0) {
    return Uint8List.sublistView(bytes, 1);
  }
  return bytes;
}
