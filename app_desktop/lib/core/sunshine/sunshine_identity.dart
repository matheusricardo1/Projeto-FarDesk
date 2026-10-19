import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:convert/convert.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Identidade do FarDesk como cliente Moonlight: um par de chaves RSA-2048 e
/// um certificado autoassinado, gerados **uma vez** e reaproveitados pra
/// sempre — é esse certificado que cada host Sunshine passa a confiar depois
/// do primeiro pareamento. Perder/trocar isso força repareamento em todo
/// dispositivo já conectado, então é persistido em disco.
///
/// `uniqueId` identifica este dispositivo-cliente pro host (parâmetro
/// `uniqueid` em toda chamada do protocolo) — também gerado uma vez.
class SunshineIdentity {
  const SunshineIdentity({required this.uniqueId, required this.privateKeyPem, required this.certificatePem});

  final String uniqueId;
  final String privateKeyPem;
  final String certificatePem;

  RSAPrivateKey get privateKey => CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

  /// Certificado em PEM, codificado em hex — é o formato que o Sunshine espera
  /// no parâmetro `clientcert` do pareamento (hex do texto PEM, não do DER cru).
  String get certificatePemHex => hex.encode(utf8.encode(certificatePem));

  /// Bytes da assinatura do certificado — usados nos desafios de pareamento
  /// pra amarrar a prova criptográfica a este certificado específico.
  List<int> get certificateSignatureBytes =>
      X509Utils.x509CertificateFromPem(certificatePem).signature!.codeUnits;

  factory SunshineIdentity._generate() {
    final uniqueId = const Uuid().v4();
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;

    final csr = X509Utils.generateRsaCsrPem({'CN': 'FarDesk'}, privateKey, publicKey);
    final certificatePem = X509Utils.generateSelfSignedCertificate(privateKey, csr, 3650 * 10);

    return SunshineIdentity(
      uniqueId: uniqueId,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
      certificatePem: certificatePem,
    );
  }

  Map<String, dynamic> _toJson() => {
        'uniqueId': uniqueId,
        'privateKeyPem': privateKeyPem,
        'certificatePem': certificatePem,
      };

  static SunshineIdentity _fromJson(Map<String, dynamic> json) => SunshineIdentity(
        uniqueId: json['uniqueId'] as String,
        privateKeyPem: json['privateKeyPem'] as String,
        certificatePem: json['certificatePem'] as String,
      );
}

/// Carrega a identidade salva em disco, ou gera e salva uma nova na primeira
/// vez. Geração de par RSA-2048 é pesada (centenas de ms) — por isso só
/// acontece uma vez por instalação, nunca por sessão.
class SunshineIdentityStore {
  SunshineIdentityStore({Directory? directory}) : _directoryOverride = directory;

  final Directory? _directoryOverride;
  SunshineIdentity? _cached;

  Future<SunshineIdentity> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final file = await _identityFile();
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _cached = SunshineIdentity._fromJson(json);
    }

    final identity = SunshineIdentity._generate();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(identity._toJson()));
    return _cached = identity;
  }

  Future<File> _identityFile() async {
    final directory = _directoryOverride ?? await getApplicationSupportDirectory();
    return File('${directory.path}/sunshine_identity.json');
  }
}
