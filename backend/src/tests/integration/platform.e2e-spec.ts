import { createTestApp } from '@tests/integration/support/create-test-app';
import type { TestApp } from '@tests/integration/support/create-test-app';

/** Cross-cutting: health, correlação, validação de entrada, guard global. */
describe('Plataforma (e2e)', () => {
  let testApp: TestApp;

  beforeAll(async () => {
    testApp = await createTestApp();
  });

  afterAll(async () => {
    await testApp.app.close();
  });

  it('GET /health é público e responde ok', async () => {
    const response = await testApp.http().get('/health').expect(200);

    expect((response.body as { status: string }).status).toBe('ok');
  });

  it('toda resposta carrega x-request-id, e respeita o enviado pelo cliente', async () => {
    const response = await testApp.http().get('/health').set('x-request-id', 'trace-123').expect(200);

    expect(response.headers['x-request-id']).toBe('trace-123');
  });

  it('GET /auth/google/sessions/:id é público e devolve 404 pra sessão desconhecida', async () => {
    await testApp.http().get('/auth/google/sessions/nao-existe').expect(404);
  });

  it('POST /integrations/tailscale/connect sem corpo é recusado pela validação', async () => {
    const response = await testApp
      .http()
      .post('/integrations/tailscale/connect')
      .set('Authorization', testApp.authHeaderFor('owner-1'))
      .send({})
      .expect(400);

    expect((response.body as { message: string }).message).toContain('apiAccessToken');
  });

  it('DELETE /integrations/:platform com plataforma desconhecida é 400', async () => {
    await testApp
      .http()
      .delete('/integrations/steam-inexistente')
      .set('Authorization', testApp.authHeaderFor('owner-1'))
      .expect(400);
  });

  it('GET /integrations começa vazio pra uma conta nova', async () => {
    const response = await testApp
      .http()
      .get('/integrations')
      .set('Authorization', testApp.authHeaderFor('nova'))
      .expect(200);

    expect(response.body).toEqual([]);
  });
});
