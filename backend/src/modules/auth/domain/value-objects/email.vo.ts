import { ValueObject } from '@shared/domain/base/value-object.base';
import { InvalidValueException } from '@shared/domain/exceptions/domain.exception';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface EmailProps {
  value: string;
}

/** Garante na criação que nunca existe uma `Account` com email mal formado. Normaliza pra minúsculas. */
export class Email extends ValueObject<EmailProps> {
  private constructor(props: EmailProps) {
    super(props);
  }

  static create(raw: string): Email {
    const value = raw.trim().toLowerCase();
    if (!EMAIL_PATTERN.test(value)) {
      throw new InvalidValueException(`"${raw}" não é um email válido.`);
    }
    return new Email({ value });
  }

  get value(): string {
    return this.props.value;
  }
}
