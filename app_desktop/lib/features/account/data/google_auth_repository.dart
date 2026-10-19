import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/result.dart';
import '../domain/account.dart';
import '../domain/auth_repository.dart';

/// Credenciais de uma conta já logada — guardadas só em memória por enquanto
/// (perde ao fechar o app). Trocar por `flutter_secure_storage` é o próximo
/// passo natural pra persistir entre reinicializações.
class _AccountSession {
  _AccountSession({required this.account, required this.accessToken, required this.refreshToken});

  final Account account;
  final String accessToken;
  final String refreshToken;
}

/// Implementação real: fala com o backend FarDesk pra logar com Google.
///
/// Como o app é desktop e o backend é remoto (não localhost), o login não
/// usa um deep link de volta pro app — ele abre o navegador do sistema no
/// fluxo do Google, e o app fica fazendo *polling* de uma "sessão de login"
/// no backend até ela ter um resultado. Ver `backend/src/modules/auth` pro
/// outro lado desse fluxo.
class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository({
    required this.backendBaseUrl,
    this.pollInterval = const Duration(milliseconds: 1500),
    this.pollTimeout = const Duration(minutes: 5),
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String backendBaseUrl;
  final Duration pollInterval;
  final Duration pollTimeout;
  final http.Client _http;

  final List<_AccountSession> _sessions = [];
  String? _activeAccountId;

  /// Token da conta ativa — é isso que outros repositórios vão anexar como
  /// `Authorization: Bearer` quando forem ligados ao backend de verdade.
  String? get activeAccessToken => _findActive()?.accessToken;

  @override
  Future<Result<AccountSession>> signIn(AuthProvider provider) => _loginWithGoogle(replaceSession: true);

  @override
  Future<Result<AccountSession>> addAccount(AuthProvider provider) => _loginWithGoogle(replaceSession: false);

  @override
  Future<Result<AccountSession>> switchAccount(String accountId) async {
    if (!_sessions.any((s) => s.account.id == accountId)) {
      return Failure(StateError('Conta não encontrada: $accountId'));
    }
    _activeAccountId = accountId;
    return Ok(_snapshot());
  }

  Future<Result<AccountSession>> _loginWithGoogle({required bool replaceSession}) async {
    try {
      final start = await _http.post(Uri.parse('$backendBaseUrl/auth/google/start'));
      if (start.statusCode != 200) {
        return Failure(StateError('Falha ao iniciar login (HTTP ${start.statusCode}).'));
      }
      final startBody = jsonDecode(start.body) as Map<String, dynamic>;
      final loginSessionId = startBody['loginSessionId'] as String;
      final authorizationUrl = startBody['authorizationUrl'] as String;

      final opened = await launchUrl(Uri.parse(authorizationUrl), mode: LaunchMode.externalApplication);
      if (!opened) {
        return Failure(StateError('Não foi possível abrir o navegador pro login do Google.'));
      }

      final polled = await _pollSession(loginSessionId);
      final _LoginOutcome outcome;
      switch (polled) {
        case Ok(:final value):
          outcome = value;
        case Failure(:final error):
          return Failure(error);
      }

      final account = outcome.account;
      final session = _AccountSession(account: account, accessToken: outcome.accessToken, refreshToken: outcome.refreshToken);

      if (replaceSession || _sessions.isEmpty) {
        _sessions
          ..clear()
          ..add(session);
      } else {
        _sessions.removeWhere((s) => s.account.id == account.id);
        _sessions.add(session);
      }
      _activeAccountId = account.id;

      return Ok(_snapshot());
    } catch (error) {
      return Failure(error);
    }
  }

  Future<Result<_LoginOutcome>> _pollSession(String loginSessionId) async {
    final deadline = DateTime.now().add(pollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final response = await _http.get(Uri.parse('$backendBaseUrl/auth/google/sessions/$loginSessionId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final status = body['status'] as String;
        if (status == 'completed') {
          final accountJson = body['account'] as Map<String, dynamic>;
          return Ok(
            _LoginOutcome(
              account: Account(
                id: accountJson['id'] as String,
                name: accountJson['displayName'] as String,
                email: accountJson['email'] as String,
                avatarUrl: accountJson['avatarUrl'] as String?,
              ),
              accessToken: body['accessToken'] as String,
              refreshToken: body['refreshToken'] as String,
            ),
          );
        }
        if (status == 'failed') {
          return Failure(StateError((body['error'] as String?) ?? 'Login falhou no Google.'));
        }
        // "pending" — continua esperando o usuário terminar no navegador.
      }
      await Future<void>.delayed(pollInterval);
    }
    return Failure(StateError('Tempo esgotado esperando o login no navegador.'));
  }

  _AccountSession? _findActive() {
    for (final session in _sessions) {
      if (session.account.id == _activeAccountId) return session;
    }
    return null;
  }

  AccountSession _snapshot() =>
      AccountSession(accounts: _sessions.map((s) => s.account).toList(growable: false), activeAccountId: _activeAccountId!);
}

class _LoginOutcome {
  _LoginOutcome({required this.account, required this.accessToken, required this.refreshToken});

  final Account account;
  final String accessToken;
  final String refreshToken;
}
