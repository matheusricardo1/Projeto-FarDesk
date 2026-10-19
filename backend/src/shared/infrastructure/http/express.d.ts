import 'express';

declare module 'express-serve-static-core' {
  interface Request {
    /** Setado por `CorrelationIdMiddleware`. */
    id?: string;
  }
}
