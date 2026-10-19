import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:xml/xml.dart';

import 'models/sunshine_app.dart';
import 'models/sunshine_launch_session.dart';
import 'models/sunshine_server_info.dart';
import 'sunshine_crypto.dart';
import 'sunshine_exception.dart';
import 'sunshine_identity.dart';
import 'sunshine_tls.dart';

/// Fala com um host Sunshine **depois** que o pareamento (`SunshinePairingClient`)
/// já aconteceu: status do host, lista de apps, e lançar/retomar sessão. Toda
/// chamada aqui usa mTLS com o certificado do host fixado (pinned) no
/// pareamento — nunca a cadeia de CAs do sistema.
class SunshineHostClient {
  SunshineHostClient({
    required this.identity,
    required this.host,
    required Uint8List pinnedServerCertDer,
    this.httpPort = 47989,
    this.httpsPort = 47984,
  }) : _pinnedServerCertDer = pinnedServerCertDer;

  final SunshineIdentity identity;
  final String host;
  final int httpPort;
  final int httpsPort;
  final Uint8List _pinnedServerCertDer;

  /// `/serverinfo` funciona sem pareamento (HTTP puro) — é o que decide se
  /// vale a pena tentar parear ou já pular pra listar apps.
  Future<SunshineServerInfo> fetchServerInfo() async {
    final xmlBody = await _getPlain(Uri.http('$host:$httpPort', '/serverinfo', {'uniqueid': identity.uniqueId}));
    final root = XmlDocument.parse(xmlBody).rootElement;
    return SunshineServerInfo(
      hostname: _text(root, 'hostname'),
      appVersion: _text(root, 'appversion'),
      uniqueId: _text(root, 'uniqueid'),
      httpsPort: int.tryParse(_text(root, 'HttpsPort')) ?? httpsPort,
      externalPort: int.tryParse(_text(root, 'ExternalPort')) ?? httpPort,
      isPaired: _text(root, 'PairStatus') == '1',
      currentGameId: int.tryParse(_text(root, 'currentgame')) ?? 0,
      state: _text(root, 'state'),
    );
  }

  Future<List<SunshineApp>> fetchAppList() async {
    final xmlBody = await _getSecure(Uri.https('$host:$httpsPort', '/applist', {'uniqueid': identity.uniqueId}));
    final root = XmlDocument.parse(xmlBody).rootElement;
    return root.findElements('App').map((app) {
      return SunshineApp(
        id: app.findElements('ID').first.innerText,
        title: app.findElements('AppTitle').first.innerText,
        isHdrSupported: app.findElements('IsHdrSupported').firstOrNull?.innerText == '1',
      );
    }).toList(growable: false);
  }

  /// [width]/[height]/[fps] definem a resolução negociada; [enableHdr] e
  /// [enableSops] (otimização automática de qualidade) seguem os mesmos
  /// defaults do Moonlight. A chave `riKey`/`riKeyId` é gerada aqui e
  /// reaproveitada pela sessão RTSP futura — ainda não existe vídeo de
  /// verdade nesse ponto da implementação, só a abertura da sessão no host.
  Future<SunshineLaunchSession> launchApp({
    required String appId,
    required int width,
    required int height,
    required int fps,
    bool playLocalAudio = false,
    bool enableSops = true,
    bool enableHdr = false,
  }) async {
    final riKey = SunshineCrypto.randomBytes(16);
    final riKeyId = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

    final query = {
      'uniqueid': identity.uniqueId,
      'appid': appId,
      'mode': '${width}x${height}x$fps',
      'additionalStates': '1',
      'sops': enableSops ? '1' : '0',
      'rikey': hex.encode(riKey),
      'rikeyid': '$riKeyId',
      'localAudioPlayMode': playLocalAudio ? '1' : '0',
      'surroundAudioInfo': '196610', // estéreo — mesmo default do Moonlight quando não há gamepad conectado.
      if (enableHdr) 'hdrMode': '1',
    };

    final xmlBody = await _getSecure(Uri.https('$host:$httpsPort', '/launch', query));
    final root = XmlDocument.parse(xmlBody).rootElement;
    if (_textOrNull(root, 'gamesession') != '1') {
      throw SunshineException('Host recusou o launch (${_statusMessage(root)}).');
    }

    return SunshineLaunchSession(sessionUrl: _text(root, 'sessionUrl0'), riKey: riKey, riKeyId: riKeyId);
  }

  Future<String> _getPlain(Uri uri, {Duration timeout = const Duration(seconds: 10)}) async {
    final client = HttpClient();
    try {
      return await _get(client, uri, timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _getSecure(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    final client = createSunshineHttpClient(identity: identity, pinnedServerCertDer: _pinnedServerCertDer);
    try {
      return await _get(client, uri, timeout);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _get(HttpClient client, Uri uri, Duration timeout) async {
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

  String _text(XmlElement root, String name) {
    final value = _textOrNull(root, name);
    if (value == null) throw SunshineException('Campo "$name" ausente na resposta do host.');
    return value;
  }

  String? _textOrNull(XmlElement root, String name) => root.findElements(name).firstOrNull?.innerText;

  String _statusMessage(XmlElement root) =>
      root.getAttribute('status_message') ?? 'sem detalhes';
}
