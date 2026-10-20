import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:path_provider/path_provider.dart';

import '../sunshine/sunshine_crypto.dart';

/// Usuário fixo da conta administrativa do Sunshine local criada pelo
/// FarDesk — não é segredo (quem autentica é a senha), só precisa ser
/// estável.
const String hostAdminUsername = 'fardesk';

/// Credenciais da API administrativa web do Sunshine local (porta 47990,
/// ver `SunshineAdminClient`) — a mesma conta que, no fluxo manual, a pessoa
/// cria na tela `/welcome` do Sunshine na primeira vez que abre a Web UI.
/// Aqui isso é feito via `HostApi.bootstrapCredentials` (chama o mesmo
/// `POST /api/password` que aquela tela chama), não escrevendo em arquivo.
///
/// Geradas automaticamente, uma única vez por instalação, e nunca expostas
/// em nenhuma tela: a pessoa não escolhe usuário/senha nem precisa lembrar
/// de nada — ela só faz login com a conta Google do FarDesk. O login com
/// Google autentica a *pessoa* na conta do FarDesk; esta credencial aqui
/// protege a API *local* de uma máquina específica — são dois escopos
/// diferentes, por isso não dá (nem faria sentido) derivar uma da outra.
class HostCredentials {
  const HostCredentials({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> _toJson() => {
    'username': username,
    'password': password,
  };

  static HostCredentials _fromJson(Map<String, dynamic> json) =>
      HostCredentials(
        username: json['username'] as String,
        password: json['password'] as String,
      );

  /// Senha em hex de 24 bytes aleatórios — reaproveita o mesmo gerador
  /// seguro que o resto do pareamento Sunshine já usa (`SunshineCrypto`),
  /// em vez de inventar outro.
  factory HostCredentials._generate() => HostCredentials(
    username: hostAdminUsername,
    password: hex.encode(SunshineCrypto.randomBytes(24)),
  );
}

/// Carrega as credenciais salvas em disco, ou gera e salva novas na
/// primeira vez — mesmo padrão do `SunshineIdentityStore`, só que pra
/// usuário/senha em vez de certificado.
class HostCredentialsStore {
  HostCredentialsStore({Directory? directory}) : _directoryOverride = directory;

  final Directory? _directoryOverride;

  HostCredentials? _cached;

  /// `true` só na chamada de `load()` que efetivamente gerou a credencial
  /// agora (primeira vez desta instalação) — é o sinal que `HostActivation`
  /// usa pra saber se precisa chamar `HostApi.bootstrapCredentials()`.
  /// Falso em qualquer carregamento subsequente, mesmo que seja a primeira
  /// chamada desta instância de `HostCredentialsStore` (se o arquivo já
  /// existia em disco, a credencial já foi configurada no Sunshine antes).
  bool generatedThisRun = false;

  Future<HostCredentials> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final file = await _credentialsFile();
    if (await file.exists()) {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _cached = HostCredentials._fromJson(json);
    }

    final credentials = HostCredentials._generate();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(credentials._toJson()));
    generatedThisRun = true;
    return _cached = credentials;
  }

  Future<void> save(HostCredentials credentials) async {
    final file = await _credentialsFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(credentials._toJson()));
    _cached = credentials;
    generatedThisRun = false;
  }

  Future<File> _credentialsFile() async {
    final directory =
        _directoryOverride ?? await getApplicationSupportDirectory();
    return File('${directory.path}/host_credentials.json');
  }
}
