import { createTestApp } from '@tests/integration/support/create-test-app';
import type { TestApp } from '@tests/integration/support/create-test-app';

describe('Pairing (e2e)', () => {
  let testApp: TestApp;
  let auth: string;

  beforeAll(async () => {
    testApp = await createTestApp();
    auth = testApp.authHeaderFor('dev-user-1'); // dono dos dispositivos semeados
  });

  afterAll(async () => {
    await testApp.app.close();
  });

  it('POST .../pairing-requests sem token retorna 401', async () => {
    await testApp.http().post('/devices/pc-matheus/pairing-requests').send({ pin: '1234' }).expect(401);
  });

  it('POST .../pairing-requests num dispositivo de outra conta retorna 404', async () => {
    await testApp
      .http()
      .post('/devices/pc-matheus/pairing-requests')
      .set('Authorization', testApp.authHeaderFor('outra-conta'))
      .send({ pin: '1234' })
      .expect(404);
  });

  it('POST .../pairing-requests com PIN mal formado é recusado pela validação', async () => {
    await testApp
      .http()
      .post('/devices/pc-matheus/pairing-requests')
      .set('Authorization', auth)
      .send({ pin: '12' })
      .expect(400);
  });

  it('fluxo completo: cliente cria → agente vê pendente → agente confirma → cliente conclui', async () => {
    const created = await testApp
      .http()
      .post('/devices/pc-matheus/pairing-requests')
      .set('Authorization', auth)
      .send({ pin: '4242' })
      .expect(201);

    const request = created.body as { id: string; deviceId: string; pin: string; status: string };
    expect(request.pin).toBe('4242');
    expect(request.status).toBe('pending');

    // O agente do host faz polling nisto — mesma conta, token diferente (ele se autentica como a própria conta).
    const pending = await testApp
      .http()
      .get('/devices/pc-matheus/pairing-requests/pending')
      .set('Authorization', auth)
      .expect(200);
    expect((pending.body as { request: { id: string } }).request.id).toBe(request.id);

    const acked = await testApp
      .http()
      .post(`/devices/pc-matheus/pairing-requests/${request.id}/ack`)
      .set('Authorization', auth)
      .expect(200);
    expect((acked.body as { status: string }).status).toBe('delivered');

    const completed = await testApp
      .http()
      .post(`/devices/pc-matheus/pairing-requests/${request.id}/complete`)
      .set('Authorization', auth)
      .expect(200);
    expect((completed.body as { status: string }).status).toBe('completed');

    // Já concluído — o agente não deve mais ver nada pendente pra esse dispositivo.
    const afterComplete = await testApp
      .http()
      .get('/devices/pc-matheus/pairing-requests/pending')
      .set('Authorization', auth)
      .expect(200);
    expect(afterComplete.body).toEqual({ request: null });
  });

  it('GET .../pending é null quando não há nenhuma solicitação em andamento', async () => {
    const response = await testApp
      .http()
      .get('/devices/notebook/pairing-requests/pending')
      .set('Authorization', auth)
      .expect(200);

    expect(response.body).toEqual({ request: null });
  });

  it('POST .../fail registra o motivo da falha', async () => {
    const created = await testApp
      .http()
      .post('/devices/notebook/pairing-requests')
      .set('Authorization', auth)
      .send({ pin: '1111' })
      .expect(201);

    const request = created.body as { id: string };
    const failed = await testApp
      .http()
      .post(`/devices/notebook/pairing-requests/${request.id}/fail`)
      .set('Authorization', auth)
      .send({ reason: 'PIN rejeitado pelo host' })
      .expect(200);

    expect(failed.body).toEqual(
      expect.objectContaining({ status: 'failed', failureReason: 'PIN rejeitado pelo host' }),
    );
  });

  it('ack de uma solicitação de outro dispositivo retorna 404', async () => {
    const created = await testApp
      .http()
      .post('/devices/pc-sala/pairing-requests')
      .set('Authorization', auth)
      .send({ pin: '9999' })
      .expect(201);

    const request = created.body as { id: string };
    await testApp
      .http()
      .post(`/devices/notebook/pairing-requests/${request.id}/ack`)
      .set('Authorization', auth)
      .expect(404);
  });
});
