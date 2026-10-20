import 'dart:convert';
import 'dart:io';

import '../sunshine/sunshine_exception.dart';
import 'host_credentials_store.dart';
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
/// máquina. Em uso normal, ninguém digita essa credencial em lugar nenhum:
/// use `SunshineAdminClient.autoProvisioned` pra obtê-la do
/// `HostCredentialsStore` automaticamente.
///
/// Endpoints confirmados lendo o bundle real da Web UI do Sunshine
/// (`assets/web/assets/*.js` do pacote portátil oficial): `/api/pin`,
/// `/api/password`, `/api/apps`, `/api/apps/close`, `/api/clients/list`,
/// `/api/clients/unpair`, `/api/clients/unpair-all`.
class SunshineAdminClient {
  SunshineAdminClient({required this.username, required this.password, this.host = 'localhost', this.port = 47990});

  /// Gera (na primeira vez) ou carrega as credenciais do admin do Sunshine
  /// local via `HostCredentialsStore`, sem pedir nada a ninguém — nenhuma
  /// tela de configuração envolvida.
  static Future<SunshineAdminClient> autoProvisioned({
    HostCredentialsStore? credentialsStore,
    String host = 'localhost',
    int port = 47990,
  }) async {
    final credentials = await (credentialsStore ?? HostCredentialsStore()).load();
    return SunshineAdminClient(username: credentials.username, password: credentials.password, host: host, port: port);
  }

  final String username;
  final String password;
  final String host;
  final int port;

  String get _basicAuth => 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Future<List<PendingSunshinePairing>> listPendingPairings() async {
    final json = await _get('/api/pin');
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
  }

  /// Submete o PIN pro pareamento identificado por [pairingId]. `true` quando
  /// o Sunshine confirma que o handshake criptográfico fechou do lado dele.
  Future<bool> submitPin({required String pairingId, required String pin, required String clientName}) async {
    final json = await _post('/api/pin', {'pairing_id': pairingId, 'pin': pin, 'name': clientName});
    return json['status'] == true;
  }

  /// Define usuário/senha do admin pela primeira vez — a mesma chamada que a
  /// tela `/welcome` faz, sem precisar de ninguém preenchendo formulário.
  /// Só funciona enquanto o Sunshine ainda não tem credencial nenhuma
  /// configurada (primeiro boot); depois disso, trocar senha exige
  /// `currentPassword`, o que esta classe de propósito não faz — a troca de
  /// senha do admin não é um fluxo que o agente automatiza.
  Future<bool> bootstrapCredentials() async {
    final json = await _post('/api/password', {
      'newUsername': username,
      'newPassword': password,
      'confirmNewPassword': password,
    });
    return json['status'] == true;
  }

  /// Apps/jogos configurados no host. Devolvido como JSON crú (em vez de um
  /// modelo tipado) porque o formato exato de cada entrada muda entre
  /// versões do Sunshine e não vale a pena travar nisso aqui.
  Future<List<Map<String, dynamic>>> listApps() async {
    final json = await _get('/api/apps');
    return (json['apps'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  }

  Future<bool> addApp(Map<String, dynamic> app) async {
    final json = await _post('/api/apps', app);
    return json['status'] == true;
  }

  Future<bool> closeApp() async {
    final json = await _post('/api/apps/close', const {});
    return json['status'] == true;
  }

  /// Clientes (dispositivos) já pareados com este host.
  Future<List<Map<String, dynamic>>> listClients() async {
    final json = await _get('/api/clients/list');
    return (json['named_certs'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  }

  Future<bool> unpairClient(String uuid) async {
    final json = await _post('/api/clients/unpair', {'uuid': uuid});
    return json['status'] == true;
  }

  Future<bool> unpairAllClients() async {
    final json = await _post('/api/clients/unpair-all', const {});
    return json['status'] == true;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final client = _client();
    try {
      final request = await client.getUrl(Uri.https('$host:$port', path));
      request.headers.set(HttpHeaders.authorizationHeader, _basicAuth);
      final response = await request.close();
      final body = await _readBody(response);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('Sunshine local recusou GET $path (HTTP ${response.statusCode}).');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final client = _client();
    try {
      final request = await client.postUrl(Uri.https('$host:$port', path));
      request.headers
        ..set(HttpHeaders.authorizationHeader, _basicAuth)
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await _readBody(response);
      if (response.statusCode != HttpStatus.ok) {
        throw SunshineException('Sunshine local recusou POST $path (HTTP ${response.statusCode}).');
      }
      return jsonDecode(body) as Map<String, dynamic>;
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
