import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:convert/convert.dart';
import 'package:xml/xml.dart';

import 'models/sunshine_pair_result.dart';
import 'sunshine_crypto.dart';
import 'sunshine_exception.dart';
import 'sunshine_identity.dart';
import 'sunshine_tls.dart';

/// Nome que o FarDesk se apresenta pro Sunshine durante o pareamento — o
/// agente do host (`HostAgentPairingService`) precisa do mesmo valor pra
/// achar, na lista de pareamentos pendentes do Sunshine local, qual é o
/// nosso, então isto é público de propósito, não um detalhe interno.
const String sunshineClientDeviceName = 'FarDesk';

/// Implementa o protocolo de pareamento do GameStream (Moonlight/Sunshine) —
/// porta direta de `PairingManager.java` (a referência oficial do projeto
/// Moonlight), com os mesmos nomes de campo e a mesma sequência de chamadas,
/// porque qualquer desvio quebra a interoperabilidade com um Sunshine real.
///
/// O PIN entra por parâmetro, nunca por UI daqui — é o backend (ou, nos
/// nossos próprios testes, um humano olhando a tela do host) quem decide
/// como esse PIN chega até aqui.
class SunshinePairingClient {
  SunshinePairingClient({
    required this.identity,
    required this.host,
    this.httpPort = 47989,
    this.httpsPort = 47984,
  });

  final SunshineIdentity identity;
  final String host;
  final int httpPort;
  final int httpsPort;

  Uri _httpUri(String path, Map<String, String> query) =>
      Uri.http('$host:$httpPort', path, query);

  Uri _httpsUri(String path, Map<String, String> query) =>
      Uri.https('$host:$httpsPort', path, query);

  Future<SunshinePairResult> pair({required String pin}) async {
    final salt = SunshineCrypto.randomBytes(16);
    final aesKey = SunshineCrypto.deriveAesKey(salt, pin);

    // Passo 1 — troca de certificados. Sem timeout curto: o host só responde
    // depois que o PIN for confirmado do lado dele (hoje, manualmente; depois,
    // pelo agente do host automaticamente).
    final getCertXml = await _get(
      _httpUri('/pair', {
        'uniqueid': identity.uniqueId,
        'devicename': sunshineClientDeviceName,
        'updateState': '1',
        'phrase': 'getservercert',
        'salt': hex.encode(salt),
        'clientcert': identity.certificatePemHex,
      }),
      timeout: const Duration(minutes: 2),
    );
    if (_field(getCertXml, 'paired') != '1') return SunshinePairResult.failed;

    final serverCertPem = _certificatePemFromHex(_field(getCertXml, 'plaincert'));
    if (serverCertPem == null) {
      // Tentar parear enquanto outro pareamento está pendente faz o
      // Sunshine devolver um certificado vazio.
      return SunshinePairResult.alreadyInProgress;
    }
    final serverCertData = X509Utils.x509CertificateFromPem(serverCertPem);
    final serverPublicKey = _rsaPublicKeyFromCertificate(serverCertData);
    final serverCertDer = serverCertificateDer(serverCertPem);
    final serverCertSignature = Uint8List.fromList(serverCertData.signature!.codeUnits);

    // Passo 2 — desafio do cliente.
    final randomChallenge = SunshineCrypto.randomBytes(16);
    final encryptedChallenge = SunshineCrypto.aesEcbEncrypt(randomChallenge, aesKey);
    final challengeXml = await _get(_httpUri('/pair', {
      'uniqueid': identity.uniqueId,
      'devicename': sunshineClientDeviceName,
      'updateState': '1',
      'clientchallenge': hex.encode(encryptedChallenge),
    }));
    if (_field(challengeXml, 'paired') != '1') {
      await _unpair();
      return SunshinePairResult.failed;
    }

    final decryptedChallengeResponse = SunshineCrypto.aesEcbDecrypt(
      Uint8List.fromList(hex.decode(_field(challengeXml, 'challengeresponse'))),
      aesKey,
    );
    const hashLength = 32; // SHA-256 — Sunshine nunca usa o SHA-1 legado do GFE antigo.
    final serverResponse = decryptedChallengeResponse.sublist(0, hashLength);
    final serverChallenge = decryptedChallengeResponse.sublist(hashLength, hashLength + 16);

    // Passo 3 — responde ao desafio do servidor e manda o nosso.
    final clientSecret = SunshineCrypto.randomBytes(16);
    final challengeRespHash = SunshineCrypto.sha256(
      SunshineCrypto.concat([serverChallenge, serverCertSignature, clientSecret]),
    );
    final secretXml = await _get(_httpUri('/pair', {
      'uniqueid': identity.uniqueId,
      'devicename': sunshineClientDeviceName,
      'updateState': '1',
      'serverchallengeresp': hex.encode(SunshineCrypto.aesEcbEncrypt(challengeRespHash, aesKey)),
    }));
    if (_field(secretXml, 'paired') != '1') {
      await _unpair();
      return SunshinePairResult.failed;
    }

    final serverSecretResp = Uint8List.fromList(hex.decode(_field(secretXml, 'pairingsecret')));
    final serverSecret = serverSecretResp.sublist(0, 16);
    final serverSignature = serverSecretResp.sublist(16, 16 + 256);

    if (!CryptoUtils.rsaVerify(serverPublicKey, serverSecret, serverSignature)) {
      await _unpair();
      return SunshinePairResult.failed; // Assinatura não bate — cheiro de man-in-the-middle.
    }

    final expectedServerResponse = SunshineCrypto.sha256(
      SunshineCrypto.concat([randomChallenge, serverCertSignature, serverSecret]),
    );
    if (!SunshineCrypto.bytesEqual(expectedServerResponse, serverResponse)) {
      await _unpair();
      return SunshinePairResult.pinWrong;
    }

    // Passo 4 — prova pro servidor que sabemos o PIN, assinando com nossa chave privada.
    final clientPairingSecret = SunshineCrypto.concat([
      clientSecret,
      Uint8List.fromList(CryptoUtils.rsaSign(identity.privateKey, clientSecret)),
    ]);
    final clientSecretXml = await _get(_httpUri('/pair', {
      'uniqueid': identity.uniqueId,
      'devicename': sunshineClientDeviceName,
      'updateState': '1',
      'clientpairingsecret': hex.encode(clientPairingSecret),
    }));
    if (_field(clientSecretXml, 'paired') != '1') {
      await _unpair();
      return SunshinePairResult.failed;
    }

    // Passo 5 — o desafio final só fecha via HTTPS com o certificado já em uso (mTLS).
    final client = createSunshineHttpClient(identity: identity, pinnedServerCertDer: serverCertDer);
    try {
      final pairChallengeXml = await _getWithClient(
        client,
        _httpsUri('/pair', {
          'uniqueid': identity.uniqueId,
          'devicename': sunshineClientDeviceName,
          'updateState': '1',
          'phrase': 'pairchallenge',
        }),
      );
      if (_field(pairChallengeXml, 'paired') != '1') {
        await _unpair();
        return SunshinePairResult.failed;
      }
    } finally {
      client.close(force: true);
    }

    return SunshinePairResult.paired;
  }

  Future<void> _unpair() async {
    try {
      await _get(_httpUri('/unpair', {'uniqueid': identity.uniqueId}));
    } catch (_) {
      // Best-effort — se o unpair falhar, a sessão pendente expira sozinha no host.
    }
  }

  Future<String> _get(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('${uri.path} respondeu HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } on SunshineException {
      rethrow;
    } catch (error) {
      throw SunshineException('Falha ao falar com o host em ${uri.path}: $error');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _getWithClient(HttpClient client, Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('${uri.path} respondeu HTTP ${response.statusCode}');
      }
      return await response.transform(utf8.decoder).join();
    } on SunshineException {
      rethrow;
    } catch (error) {
      throw SunshineException('Falha ao falar com o host em ${uri.path}: $error');
    }
  }

  String _field(String xmlBody, String name) {
    final document = XmlDocument.parse(xmlBody);
    final element = document.rootElement.findElements(name).firstOrNull;
    if (element == null) throw SunshineException('Campo "$name" ausente na resposta do host.');
    return element.innerText;
  }

  /// `plaincert` vem em hex — tanto PEM quanto, em tese, DER cru dependendo da
  /// versão do host. Tentamos PEM primeiro (é o formato real do Sunshine) e
  /// convertemos DER pra PEM como rede de segurança.
  String? _certificatePemFromHex(String hexValue) {
    if (hexValue.isEmpty) return null;
    final bytes = Uint8List.fromList(hex.decode(hexValue));
    final asText = utf8.decode(bytes, allowMalformed: true);
    if (asText.contains('-----BEGIN CERTIFICATE-----')) return asText;

    final base64Body = base64.encode(bytes);
    final chunks = <String>[];
    for (var i = 0; i < base64Body.length; i += 64) {
      chunks.add(base64Body.substring(i, i + 64 > base64Body.length ? base64Body.length : i + 64));
    }
    return '-----BEGIN CERTIFICATE-----\n${chunks.join('\n')}\n-----END CERTIFICATE-----';
  }

  /// `subjectPublicKeyInfo.bytes` é o DER completo (algoritmo + bit string)
  /// — exatamente o formato que `rsaPublicKeyFromDERBytes` espera.
  RSAPublicKey _rsaPublicKeyFromCertificate(X509CertificateData certificate) {
    final infoBytes = certificate.tbsCertificate!.subjectPublicKeyInfo.bytes!;
    return CryptoUtils.rsaPublicKeyFromDERBytes(Uint8List.fromList(infoBytes.codeUnits));
  }
}
