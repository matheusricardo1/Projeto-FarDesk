/**
 * O callback do Google é aberto no navegador do sistema, não pelo app — a
 * resposta é uma página HTML pro usuário, não JSON.
 */
export class AuthCallbackPresenter {
  static success(): string {
    return AuthCallbackPresenter.render('Login concluído', 'Pode fechar esta janela e voltar pro FarDesk.');
  }

  static failure(reason: string): string {
    return AuthCallbackPresenter.render(
      'Falha no login',
      `Algo deu errado: ${escapeHtml(reason)}. Volte pro FarDesk e tente de novo.`,
    );
  }

  private static render(title: string, message: string): string {
    return `<!doctype html>
<html lang="pt-BR">
  <head><meta charset="utf-8" /><title>FarDesk — ${title}</title></head>
  <body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #0f0f12; color: #f2f2f2;">
    <div style="text-align: center;">
      <h1>${title}</h1>
      <p>${message}</p>
    </div>
  </body>
</html>`;
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
