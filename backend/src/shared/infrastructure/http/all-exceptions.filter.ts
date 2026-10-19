import { Catch, HttpException, HttpStatus, Logger } from '@nestjs/common';
import type { ArgumentsHost, ExceptionFilter } from '@nestjs/common';
import type { Request, Response } from 'express';

import { ApplicationException } from '@shared/domain/exceptions/application.exception';
import {
  BusinessRuleViolationException,
  DomainException,
  EntityNotFoundException,
  InvalidValueException,
} from '@shared/domain/exceptions/domain.exception';
import { AppConfigService } from '@shared/infrastructure/config/app-config.service';

const STATUS_BY_DOMAIN_EXCEPTION = new Map<new (...args: never[]) => DomainException, HttpStatus>([
  [EntityNotFoundException, HttpStatus.NOT_FOUND],
  [BusinessRuleViolationException, HttpStatus.CONFLICT],
  [InvalidValueException, HttpStatus.BAD_REQUEST],
]);

interface ErrorResponseBody {
  statusCode: number;
  error: string;
  message: string;
  requestId: string | null;
}

/**
 * Único lugar que traduz qualquer exceção pra HTTP. Domínio, aplicação e
 * exceções nativas do Nest saem com a mensagem real (fazem parte do
 * contrato); erro desconhecido nunca vaza detalhe em produção.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionsHandler');

  constructor(private readonly config: AppConfigService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const request = host.switchToHttp().getRequest<Request>();
    const requestId = request.id ?? null;

    const body = this.toResponseBody(exception, requestId);
    this.logException(exception, body);
    response.status(body.statusCode).json(body);
  }

  private toResponseBody(exception: unknown, requestId: string | null): ErrorResponseBody {
    if (exception instanceof DomainException) {
      return {
        statusCode: this.statusForDomainException(exception),
        error: exception.code,
        message: exception.message,
        requestId,
      };
    }

    if (exception instanceof ApplicationException) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        error: exception.code,
        message: exception.message,
        requestId,
      };
    }

    if (exception instanceof HttpException) {
      const message = this.extractHttpExceptionMessage(exception.getResponse(), exception.message);
      return { statusCode: exception.getStatus(), error: exception.name, message, requestId };
    }

    const message =
      this.config.isProduction || !(exception instanceof Error)
        ? 'Erro interno inesperado.'
        : exception.message;
    return { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, error: 'InternalServerError', message, requestId };
  }

  private extractHttpExceptionMessage(payload: unknown, fallback: string): string {
    if (typeof payload === 'string') return payload;
    if (payload && typeof payload === 'object' && 'message' in payload) {
      const message = payload.message;
      if (Array.isArray(message)) return message.join('; ');
      if (typeof message === 'string') return message;
    }
    return fallback;
  }

  private statusForDomainException(exception: DomainException): HttpStatus {
    for (const [exceptionClass, status] of STATUS_BY_DOMAIN_EXCEPTION) {
      if (exception instanceof exceptionClass) return status;
    }
    return HttpStatus.UNPROCESSABLE_ENTITY;
  }

  private logException(exception: unknown, body: ErrorResponseBody): void {
    const prefix = `[${body.requestId ?? '-'}] ${body.statusCode} ${body.error}`;
    if (body.statusCode >= 500) {
      this.logger.error(
        `${prefix}: ${body.message}`,
        exception instanceof Error ? exception.stack : undefined,
      );
    } else {
      this.logger.warn(`${prefix}: ${body.message}`);
    }
  }
}
