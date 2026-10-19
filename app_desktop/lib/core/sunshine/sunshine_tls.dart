import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';

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
