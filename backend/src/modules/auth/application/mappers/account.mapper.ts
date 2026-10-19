import type { Account } from '@modules/auth/domain/aggregates/account.aggregate';
import type { AccountResponseDto } from '@modules/auth/application/dtos/account-response.dto';

export class AccountMapper {
  static toResponse(account: Account): AccountResponseDto {
    return {
      id: account.id.value,
      email: account.email,
      displayName: account.displayName,
      avatarUrl: account.avatarUrl,
    };
  }
}
