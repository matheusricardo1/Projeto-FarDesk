// CommonJS de propósito: roda via `setupFiles` do Jest, antes de qualquer
// módulo ESM dos testes ser avaliado. Setar isso dentro do próprio teste
// (ESM, sob --experimental-vm-modules) não chega a tempo no process.env
// que o @nestjs/config lê ao compilar o AppModule.
const { randomBytes } = require('node:crypto');

process.env.AUTH_JWT_SECRET ??= randomBytes(32).toString('base64');
process.env.INTEGRATIONS_MASTER_KEY ??= randomBytes(32).toString('base64');
