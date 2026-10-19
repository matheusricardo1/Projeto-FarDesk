# Arquitetura do backend

NestJS, Arquitetura Hexagonal (Ports & Adapters) + DDD, serverless-ready (Vercel).

## Estrutura

```
src/
├── main.ts
├── app.module.ts
│
├── shared/
│   ├── domain/
│   │   ├── base/            entity.base · aggregate-root.base · value-object.base · domain-event.base
│   │   ├── exceptions/      domain.exception (NotFound/BusinessRule/InvalidValue) · application.exception
│   │   └── types/           result.ts
│   ├── application/
│   │   └── ports/           use-case.port · unit-of-work.port · event-publisher.port
│   └── infrastructure/
│       ├── database/        unit-of-work.impl (+ prisma/ quando entrar)
│       ├── messaging/       publisher de eventos de domínio (EventEmitter2)
│       ├── config/          AppConfigService + validação de env
│       ├── http/            AllExceptionsFilter · LoggingInterceptor · CorrelationId · @Public · configureApp
│       ├── security/        rate limiting
│       └── health/          GET /health
│
├── modules/<contexto>/                  ← auth · devices · integrations · pairing
│   ├── <contexto>.module.ts             composition root: liga cada porta à implementação
│   ├── domain/                          núcleo puro — zero @nestjs, zero I/O
│   │   ├── aggregates/                  <nome>.aggregate.ts
│   │   ├── entities/                    (quando um agregado tiver entidades filhas)
│   │   ├── value-objects/               <nome>.vo.ts (ids, enums de status, Email...)
│   │   ├── events/                      <fato>.event.ts
│   │   ├── exceptions/                  <regra>.exception.ts — uma por arquivo
│   │   ├── repositories/                <nome>.repository.ts — porta de persistência
│   │   └── services/                    <nome>.domain-service.ts — regra que não cabe num agregado
│   ├── application/
│   │   ├── ports/in/                    <caso>.use-case.ts — interface + token de DI
│   │   ├── ports/out/                   gateways externos (Google, Tailscale, cipher...)
│   │   ├── use-cases/                   <caso>.use-case.impl.ts
│   │   ├── dtos/                        entrada e saída dos casos de uso
│   │   └── mappers/                     agregado → DTO de resposta
│   └── infrastructure/
│       ├── persistence/                 <nome>.repository.impl.ts + mappers/<nome>.persistence.mapper.ts
│       ├── messaging/                   listeners dos eventos do contexto
│       ├── http/                        controller (+ presenter quando a saída não é JSON)
│       └── gateways/ · security/ · platforms/   adapters das portas de saída
│
└── tests/
    ├── unit/<contexto>/                 agregados, VOs, domain services, casos de uso com fakes
    └── integration/                     app real (AppModule + configureApp) via supertest
```

## Imports

Sempre por alias, nunca relativo, sem extensão:

```ts
import { Result } from '@shared/domain/types/result';
import { Device } from '@modules/devices/domain/aggregates/device.aggregate';
```

| Alias | Aponta pra |
|---|---|
| `@app.module` | `src/app.module.ts` |
| `@shared/*` | `src/shared/*` |
| `@modules/*` | `src/modules/*` |
| `@tests/*` | `src/tests/*` |

Onde cada parte resolve:

- **TypeScript**: `paths` no `tsconfig.json`. Os alvos terminam em `.ts`
  porque, em `NodeNext`, o TS não completa extensão de import via `paths`.
- **Runtime (Node)**: o `tsc` não reescreve aliases, então
  `scripts/resolve-aliases.mjs` roda depois do build (`npm run build`) e troca
  cada alias no `dist/` pelo caminho relativo real com `.js`. Ele falha o
  build se um alias apontar pra um arquivo que não existe.
- **Jest**: `moduleNameMapper` no `package.json` (unitários) e no `jest-e2e.json` (integração).

Alias novo = entrada nova no `tsconfig.json`, no regex do script e nos dois
`moduleNameMapper`.

## Regras

**Dependência entre camadas**: `domain` não importa nada de fora dele.
`application` importa só `domain` (e `shared/application`). `infrastructure`
importa as duas. Nunca o inverso.

**O agregado não sai da aplicação.** Casos de uso devolvem DTOs (via
`application/mappers`); controllers só repassam. Credencial cifrada,
props internas etc. ficam estruturalmente impossíveis de vazar na API.

**Controllers dependem de portas de entrada, não de implementações**:
`@Inject(START_SESSION_USE_CASE) startSession: StartSessionUseCase`. O módulo
decide qual classe atende cada token.

**Repositório guarda registros, não agregados.** O mapper de persistência
converte agregado ↔ registro primitivo (como uma linha de tabela) — trocar
o adapter em memória por Prisma é reimplementar o repositório sobre o mesmo
mapper.

**Eventos de domínio**: o agregado acumula (`addDomainEvent`), o repositório
publica depois de persistir (`publishDomainEvents`), listeners em
`infrastructure/messaging` reagem.

**Exceções**: regra de negócio → subclasse de `EntityNotFoundException`
(404), `BusinessRuleViolationException` (409) ou `InvalidValueException`
(400). Provedor externo recusando algo → `ExternalProviderException` (400).
Casos de uso retornam isso em `Result`; o `AllExceptionsFilter` traduz.

**Unit of Work**: caso de uso que persiste mais de um agregado envolve os
`save()` em `unitOfWork.runInTransaction(...)` (ex: `CompleteGoogleLogin`).
A implementação em memória só executa; a do Prisma vai abrir transação.

## Consulta entre contextos (porta de saída)

`pairing` precisa saber se um `deviceId` pertence à conta que está chamando,
mas isso é dado de `devices`, outro bounded context. Padrão: definir uma
porta de saída estreita (`DeviceLookupGateway`, só com o que o contexto
precisa — não o `DeviceRepository` inteiro) e implementar o adapter em
`infrastructure/gateways/`, que aí sim importa `devices` de verdade (DI
tokens, repositório). É o único arquivo do contexto que conhece o outro;
domínio e aplicação de `pairing` só conhecem a porta. Pré-requisito: o
módulo dono do dado exporta o token (`DevicesModule` exporta
`DEVICE_REPOSITORY`) e o módulo consumidor importa o módulo (`PairingModule`
importa `DevicesModule`).

## Cuidados com decorators + `import type`

Qualquer classe usada como tipo de `@Body()`/`@Param()`/`@Query()` (DTO com
decorators do `class-validator`) **tem que ser import de valor, nunca
`import type`**. O `ValidationPipe` depende de `emitDecoratorMetadata` +
`reflect-metadata` capturando a classe de verdade em runtime pra saber o que
validar; com `import type` o import desaparece na compilação, a metadata vira
vazia, e a validação simplesmente não roda — sem erro nenhum, só passa tudo
batido. (Encontrado de verdade no `PairingController`: um PIN de 2 dígitos
passava direto porque o DTO tinha sido importado como `import type`.)

## Endpoint que pode não ter nada pra devolver

Um controller do Nest que retorna `null` literal faz o adapter Express
mandar corpo **vazio**, não o JSON `null` — quem chama recebe `{}`, não
`null`. Nunca tipar um método de controller como `Promise<T | null>` puro;
envelopar (`{ campo: T | null }`) — ver `GET .../pairing-requests/pending`
(`PendingPairingRequestResponseDto`).

## Novo bounded context

1. Copie a árvore de `modules/devices`.
2. Domínio: VOs, agregado, exceções, eventos, porta de repositório.
3. Aplicação: DTOs, mapper, uma porta de entrada + uma impl por caso de uso,
   portas de saída pra qualquer dependência externa.
4. Infraestrutura: repositório + mapper de persistência, adapters, controller.
5. `<contexto>.module.ts` ligando tokens a classes; importe em `app.module.ts`.
6. Testes em `src/tests/unit/<contexto>/` e, se expõe HTTP, em `src/tests/integration/`.

## Adiado de propósito

- **Prisma/Supabase**: a pasta `shared/infrastructure/database/prisma/` nasce
  quando o banco entrar — os repositórios em memória já têm o mesmo contrato.
- **Outbox pattern**: eventos são publicados em processo após o `save()`.
  Com banco real, revisar se save + publish precisam de consistência garantida.
- **CQRS formal**: os casos de uso são pequenos o bastante; um bus seria indireção sem ganho.
- **Refresh token endpoint**: o refresh token já é emitido, falta o endpoint de troca.
