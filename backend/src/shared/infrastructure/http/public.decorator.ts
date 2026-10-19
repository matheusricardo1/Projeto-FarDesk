import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/** Isenta a rota do `JwtAuthGuard` global. */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
