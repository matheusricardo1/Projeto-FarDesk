import '../../../core/result.dart';
import '../domain/account.dart';
import '../domain/auth_repository.dart';

/// Implementação em memória pra desenvolver a UI sem backend.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;

  final List<Account> _accounts = [];
  String? _activeId;

  @override
  Future<Result<AccountSession?>> restoreSession() async => const Ok(null);

  @override
  Future<Result<AccountSession>> signIn(AuthProvider provider) async {
    await Future<void>.delayed(latency);
    if (_accounts.isEmpty) {
      _accounts.addAll(const [
        Account(id: 'acc-matheus', name: 'Matheus', email: 'matheusricardo164@gmail.com'),
        Account(id: 'acc-trabalho', name: 'Matheus (Trabalho)', email: 'matheus.trabalho@empresa.com'),
      ]);
    }
    _activeId = _accounts.first.id;
    return Ok(_snapshot());
  }

  @override
  Future<Result<AccountSession>> addAccount(AuthProvider provider) async {
    await Future<void>.delayed(latency);
    final number = _accounts.length + 1;
    _accounts.add(Account(id: 'acc-$number', name: 'Nova conta', email: 'conta$number@gmail.com'));
    return Ok(_snapshot());
  }

  @override
  Future<Result<AccountSession>> switchAccount(String accountId) async {
    await Future<void>.delayed(latency ~/ 2);
    if (!_accounts.any((a) => a.id == accountId)) {
      return Failure(StateError('Conta não encontrada: $accountId'));
    }
    _activeId = accountId;
    return Ok(_snapshot());
  }

  AccountSession _snapshot() => AccountSession(accounts: List.unmodifiable(_accounts), activeAccountId: _activeId!);
}
