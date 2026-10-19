import { Email } from '@modules/auth/domain/value-objects/email.vo';
import { InvalidValueException } from '@shared/domain/exceptions/domain.exception';

describe('Email', () => {
  it('normaliza pra minúsculas e sem espaços', () => {
    expect(Email.create('  Matheus@Gmail.COM ').value).toBe('matheus@gmail.com');
  });

  it('recusa formato inválido', () => {
    expect(() => Email.create('nao-e-email')).toThrow(InvalidValueException);
  });

  it('igualdade é por valor', () => {
    expect(Email.create('a@b.com').equals(Email.create('A@B.com'))).toBe(true);
  });
});
