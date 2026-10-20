import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class HostCredentialDto {
  @IsString()
  @IsNotEmpty()
  username!: string;

  @IsString()
  @MinLength(16)
  password!: string;
}

export interface HostCredential {
  username: string;
  password: string;
}
