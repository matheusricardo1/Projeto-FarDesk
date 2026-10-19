/// Closure que devolve o token de acesso da conta ativa no momento da
/// chamada — nunca um valor fixo, porque o usuário pode trocar de conta
/// (ou ainda não ter logado) entre uma chamada e outra.
typedef AccessTokenProvider = String? Function();
