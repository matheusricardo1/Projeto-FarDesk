import {
  CanActivate,
  ExecutionContext,
  Injectable,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Request } from 'express';

interface Bucket {
  count: number;
  expiresAt: number;
}

/** Limite local por instância: 100 requisições por minuto para cada IP. */
@Injectable()
export class RateLimitGuard implements CanActivate {
  private static readonly limit = 100;
  private static readonly windowMs = 60_000;
  private readonly buckets = new Map<string, Bucket>();

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const now = Date.now();
    const key = this.clientKey(request);
    const current = this.buckets.get(key);
    const bucket =
      current && current.expiresAt > now
        ? current
        : { count: 0, expiresAt: now + RateLimitGuard.windowMs };

    bucket.count += 1;
    this.buckets.set(key, bucket);
    this.removeExpired(now);

    if (bucket.count > RateLimitGuard.limit) {
      throw new HttpException(
        'Limite de requisições excedido.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    return true;
  }

  private clientKey(request: Request): string {
    const forwardedFor = request.headers['x-forwarded-for'];
    if (typeof forwardedFor === 'string' && forwardedFor.length > 0) {
      return forwardedFor.split(',')[0].trim();
    }
    return request.ip || request.socket.remoteAddress || 'unknown';
  }

  private removeExpired(now: number): void {
    for (const [key, bucket] of this.buckets) {
      if (bucket.expiresAt <= now) {
        this.buckets.delete(key);
      }
    }
  }
}
