import { Injectable, Logger } from '@nestjs/common';
import type { CallHandler, ExecutionContext, NestInterceptor } from '@nestjs/common';
import type { Request, Response } from 'express';
import type { Observable } from 'rxjs';

/**
 * Uma linha por request. Loga no `finish` da resposta porque, em caso de
 * erro, o status final só é escrito depois pelo `AllExceptionsFilter`.
 */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const start = Date.now();

    response.on('finish', () => {
      const line = `${request.method} ${request.originalUrl} ${response.statusCode} +${Date.now() - start}ms [${request.id ?? '-'}]`;
      if (response.statusCode >= 500) {
        this.logger.error(line);
      } else {
        this.logger.log(line);
      }
    });

    return next.handle();
  }
}
