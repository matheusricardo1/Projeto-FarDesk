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
}
