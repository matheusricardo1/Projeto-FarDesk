import '../../../core/result.dart';
import 'account.dart';

/// Autenticação e gerenciamento de múltiplas contas no dispositivo. A
/// implementação real usa o backend FarDesk (Google OAuth abre o navegador e
/// entrega o resultado ao app por polling).
abstract interface class AuthRepository {
  Future<Result<AccountSession?>> restoreSession();

  Future<Result<AccountSession>> signIn(AuthProvider provider);

  /// Conecta mais uma conta sem desconectar as atuais.
  Future<Result<AccountSession>> addAccount(AuthProvider provider);

  Future<Result<AccountSession>> switchAccount(String accountId);

  /// Desconecta uma conta deste dispositivo — apaga a sessão salva
  /// localmente, não afeta a conta Google em si. Se era a conta ativa, outra
  /// conta já logada assume sozinha; sem nenhuma sobrando, devolve `null` e
  /// o app volta pra tela de login.
  Future<Result<AccountSession?>> signOut(String accountId);
}
