import 'package:app_desktop/features/account/data/mock_auth_repository.dart';
import 'package:app_desktop/features/account/domain/account.dart';
import 'package:app_desktop/features/account/presentation/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionViewModel session;

  setUp(() => session = SessionViewModel(MockAuthRepository(latency: Duration.zero)));

  test('começa deslogado', () {
    expect(session.isSignedIn, isFalse);
    expect(session.activeAccount, isNull);
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
}
