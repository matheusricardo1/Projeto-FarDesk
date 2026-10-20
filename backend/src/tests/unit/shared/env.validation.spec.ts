import { validateEnvironment } from '@shared/infrastructure/config/env.validation';

const VALID_ENV = {
  AUTH_JWT_SECRET: 'a'.repeat(32),
  INTEGRATIONS_MASTER_KEY: 'b'.repeat(32),
  DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
};

describe('validateEnvironment', () => {
  it('aceita um ambiente válido e aplica os defaults', () => {
    const env = validateEnvironment(VALID_ENV);

    expect(env.PORT).toBe(3000);
    expect(env.AUTH_JWT_SECRET).toBe(VALID_ENV.AUTH_JWT_SECRET);
  });

  it('recusa subir sem AUTH_JWT_SECRET', () => {
    expect(() => validateEnvironment({ INTEGRATIONS_MASTER_KEY: VALID_ENV.INTEGRATIONS_MASTER_KEY })).toThrow(
      /AUTH_JWT_SECRET/,
    );
  });

  it('recusa subir sem INTEGRATIONS_MASTER_KEY', () => {
    expect(() => validateEnvironment({ AUTH_JWT_SECRET: VALID_ENV.AUTH_JWT_SECRET })).toThrow(
      /INTEGRATIONS_MASTER_KEY/,
    );
  });

  it('recusa um PORT fora da faixa válida', () => {
    expect(() => validateEnvironment({ ...VALID_ENV, PORT: '70000' })).toThrow();
  });

  it('aceita Google ausente — essas env vars são opcionais', () => {
    expect(validateEnvironment(VALID_ENV).GOOGLE_CLIENT_ID).toBeUndefined();
  });
});
