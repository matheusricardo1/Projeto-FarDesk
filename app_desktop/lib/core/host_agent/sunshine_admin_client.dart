import 'dart:convert';
import 'dart:io';

import '../sunshine/sunshine_exception.dart';
import 'models/pending_sunshine_pairing.dart';

/// Fala com a API local da própria UI web do Sunshine (`confighttp.cpp`,
/// porta 47990 por padrão) — não confundir com `SunshineHostClient`, que
/// fala o protocolo GameStream (porta 47984) como qualquer Moonlight.
///
/// É essa API que, no fluxo manual, a pessoa usa clicando em "Enter PIN" na
/// tela do Sunshine. Aqui o agente faz exatamente a mesma chamada que o
/// clique faria — só que sozinho, assim que o backend do FarDesk avisa que
/// tem um PIN esperando. Exige o usuário/senha do admin do Sunshine (o
/// mesmo configurado na tela `/welcome` dele na primeira vez) — é a única
/// credencial que o agente precisa conhecer localmente, nunca sai desta
/// máquina.
class SunshineAdminClient {
  SunshineAdminClient({required this.username, required this.password, this.host = 'localhost', this.port = 47990});

  final String username;
  final String password;
  final String host;
  final int port;

  String get _basicAuth => 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Future<List<PendingSunshinePairing>> listPendingPairings() async {
    final client = _client();
    try {
      final request = await client.getUrl(Uri.https('$host:$port', '/api/pin'));
      request.headers.set(HttpHeaders.authorizationHeader, _basicAuth);
      final response = await request.close();
      final body = await _readBody(response);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('Sunshine local recusou listar pareamentos pendentes (HTTP ${response.statusCode}).');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final pairings = (json['pairings'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      return pairings
          .map(
            (pairing) => PendingSunshinePairing(
              pairingId: pairing['id'] as String,
              deviceName: pairing['name'] as String,
              address: pairing['address'] as String,
            ),
          )
          .toList(growable: false);
    } finally {
      client.close(force: true);
    }
  }

  /// Submete o PIN pro pareamento identificado por [pairingId]. `true` quando
  /// o Sunshine confirma que o handshake criptográfico fechou do lado dele.
  Future<bool> submitPin({required String pairingId, required String pin, required String clientName}) async {
    final client = _client();
    try {
      final request = await client.postUrl(Uri.https('$host:$port', '/api/pin'));
      request.headers
        ..set(HttpHeaders.authorizationHeader, _basicAuth)
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode({'pairing_id': pairingId, 'pin': pin, 'name': clientName}));
      final response = await request.close();
      final body = await _readBody(response);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('Sunshine local recusou o PIN (HTTP ${response.statusCode}).');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['status'] == true;
    } finally {
      client.close(force: true);
    }
  }

  /// O Sunshine local é sempre autoassinado (é a própria máquina falando
  /// consigo mesma via `localhost`) — não faz sentido validar contra uma CA,
  /// e não há um certificado prévio pra fixar como no `SunshineHostClient`.
  HttpClient _client() => HttpClient()..badCertificateCallback = (cert, host, port) => true;

  Future<String> _readBody(HttpClientResponse response) => response.transform(utf8.decoder).join();
}
