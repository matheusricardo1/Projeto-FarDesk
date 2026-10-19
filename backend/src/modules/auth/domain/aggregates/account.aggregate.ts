import { AggregateRoot } from '@shared/domain/base/aggregate-root.base';
import { AccountLoggedInEvent } from '@modules/auth/domain/events/account-logged-in.event';
import { AccountId } from '@modules/auth/domain/value-objects/account-id.vo';
import { Email } from '@modules/auth/domain/value-objects/email.vo';

export interface AccountProps {
  id: AccountId;
  googleSub: string;
  email: Email;
  displayName: string;
  avatarUrl: string | null;
  createdAt: Date;
  lastLoginAt: Date;
}

/**
 * Conta FarDesk. A identidade é o `googleSub` (estável), não o email (pode
 * mudar no Google). Nasce no primeiro login; os seguintes sincronizam perfil.
 */
export class Account extends AggregateRoot<AccountId> {
  private props: AccountProps;

  private constructor(props: AccountProps) {
    super(props.id);
    this.props = props;
  }

  /**
   * Sem evento aqui: quem cria sempre chama `recordGoogleLogin` logo em
   * seguida (conta nova ou não) — é lá que o evento nasce, uma vez só.
   */
  static createFromGoogle(props: {
    googleSub: string;
    email: string;
    displayName: string;
    avatarUrl: string | null;
    now: Date;
  }): Account {
    return new Account({
      id: AccountId.create(),
      googleSub: props.googleSub,
      email: Email.create(props.email),
      displayName: props.displayName,
      avatarUrl: props.avatarUrl,
      createdAt: props.now,
      lastLoginAt: props.now,
    });
  }

  static reconstruct(props: AccountProps): Account {
    return new Account(props);
  }

  get googleSub(): string {
    return this.props.googleSub;
  }

  get email(): string {
    return this.props.email.value;
  }

  get displayName(): string {
    return this.props.displayName;
  }

  get avatarUrl(): string | null {
    return this.props.avatarUrl;
  }

  recordGoogleLogin(props: {
    email: string;
    displayName: string;
    avatarUrl: string | null;
    now: Date;
  }): void {
    this.props.email = Email.create(props.email);
    this.props.displayName = props.displayName;
    this.props.avatarUrl = props.avatarUrl;
    this.props.lastLoginAt = props.now;
    this.addDomainEvent(new AccountLoggedInEvent(this.id.value, this.props.email.value));
  }

  toSnapshot(): Readonly<AccountProps> {
    return { ...this.props };
  }
}
