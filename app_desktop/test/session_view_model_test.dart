import 'package:app_desktop/core/result.dart';
import 'package:app_desktop/features/account/data/mock_auth_repository.dart';
import 'package:app_desktop/features/account/domain/account.dart';
import 'package:app_desktop/features/account/presentation/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionViewModel session;

  setUp(
    () =>
        session = SessionViewModel(MockAuthRepository(latency: Duration.zero)),
  );

  test('começa deslogado', () {
    expect(session.isSignedIn, isFalse);
    expect(session.activeAccount, isNull);
  });

  test('restaura uma sessão salva pelo repositório', () async {
    final repository = _RestoringAuthRepository();
    session = SessionViewModel(repository);

    await Future<void>.delayed(Duration.zero);

    expect(session.isSignedIn, isTrue);
    expect(session.activeAccount?.email, 'salva@example.com');
  });

  test('entrar cria a sessão com a primeira conta ativa', () async {
    await session.signIn(AuthProvider.google);

    expect(session.isSignedIn, isTrue);
    expect(session.activeAccount, session.accounts.first);
    expect(session.pendingSignIn, isNull);
  });

  test('adicionar conta mantém as atuais e não troca a ativa', () async {
    await session.signIn(AuthProvider.google);
    final before = session.accounts.length;
    final active = session.activeAccount;

    await session.addAccount();

    expect(session.accounts.length, before + 1);
    expect(session.activeAccount, active);
  });

  test('trocar de conta muda a conta ativa', () async {
    await session.signIn(AuthProvider.google);
    final other = session.accounts.last;

    await session.switchAccount(other.id);

    expect(session.activeAccount?.id, other.id);
  });

  test('sair com outra conta logada passa a usar ela, sem deslogar de tudo', () async {
    await session.signIn(AuthProvider.google);
    final leaving = session.activeAccount!;
    final remaining = session.accounts.firstWhere((a) => a.id != leaving.id);

    await session.signOut();

    expect(session.isSignedIn, isTrue);
    expect(session.accounts.any((a) => a.id == leaving.id), isFalse);
    expect(session.activeAccount?.id, remaining.id);
    expect(session.isSigningOut, isFalse);
  });

  test('sair da última conta volta pra tela de login', () async {
    await session.signIn(AuthProvider.google);
    expect(session.accounts.length, 2);

    await session.signOut();
    expect(session.isSignedIn, isTrue, reason: 'ainda sobrou uma conta');

    await session.signOut();

    expect(session.isSignedIn, isFalse);
    expect(session.activeAccount, isNull);
  });
}

class _RestoringAuthRepository extends MockAuthRepository {
  @override
  Future<Result<AccountSession?>> restoreSession() async => Ok(
    const AccountSession(
      accounts: [
        Account(id: 'saved', name: 'Conta salva', email: 'salva@example.com'),
      ],
      activeAccountId: 'saved',
    ),
  );
}
