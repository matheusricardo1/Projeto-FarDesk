import { createTestApp } from '@tests/integration/support/create-test-app';
import type { TestApp } from '@tests/integration/support/create-test-app';

describe('Devices (e2e)', () => {
  let testApp: TestApp;
  let auth: string;

  beforeAll(async () => {
    testApp = await createTestApp();
    // dono de todos os dispositivos semeados
    auth = testApp.authHeaderFor('dev-user-1');
  });

  afterAll(async () => {
    await testApp.app.close();
  });

  it('GET /devices sem token retorna 401', async () => {
    await testApp.http().get('/devices').expect(401);
  });

  it('GET /devices com token inválido retorna 401', async () => {
    await testApp.http().get('/devices').set('Authorization', 'Bearer lixo.lixo.lixo').expect(401);
  });

  it('GET /devices lista os dispositivos semeados do dono', async () => {
    const response = await testApp.http().get('/devices').set('Authorization', auth).expect(200);

    const names = (response.body as Array<{ name: string }>).map((device) => device.name);
    expect(names).toHaveLength(6);
    expect(names).toContain('PC do Matheus');
  });

  it('outra conta não enxerga os dispositivos', async () => {
    const response = await testApp
      .http()
      .get('/devices')
      .set('Authorization', testApp.authHeaderFor('outra'))
      .expect(200);

    expect(response.body).toEqual([]);
  });

  it('POST /devices/:id/connect num dispositivo online muda pra inUse', async () => {
    const response = await testApp
      .http()
      .post('/devices/notebook/connect')
      .set('Authorization', auth)
      .expect(200);

    expect((response.body as { status: string }).status).toBe('inUse');
  });

  it('POST /devices/:id/connect num dispositivo já em uso retorna 409', async () => {
    const response = await testApp
      .http()
      .post('/devices/pc-sala/connect')
      .set('Authorization', auth)
      .expect(409);

    const body = response.body as { error: string; requestId: string | null };
    expect(body.error).toBe('CONFLICT');
    expect(typeof body.requestId).toBe('string');
  });

  it('POST /devices/:id/connect num dispositivo inexistente retorna 404', async () => {
    await testApp.http().post('/devices/nao-existe/connect').set('Authorization', auth).expect(404);
  });

  it('POST /devices/:id/heartbeat devolve o intervalo adaptativo', async () => {
    const response = await testApp
      .http()
      .post('/devices/pc-matheus/heartbeat')
      .set('Authorization', auth)
      .expect(200);

    expect((response.body as { nextHeartbeatIntervalSeconds: number }).nextHeartbeatIntervalSeconds).toBe(60);
  });
});
