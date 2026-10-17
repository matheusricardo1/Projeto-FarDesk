# FarDesk — Panorama do projeto

Open source, estilo "AnyDesk de jogos". Streaming de jogos remoto com qualquer dispositivo cliente (navegador, Android/TV, iPhone, PC), host fácil de configurar, multi-sessão, PS5 integrado, tudo sob uma conta central.

## Nome
**FarDesk** — escolhido depois de descartar várias opções por conflito de marca/produto existente:
- FarPlay: já é um app comercial real (farplay.io, colaboração musical remota) — descartado
- Quasar, Rainway: já existem como ferramentas de acesso remoto/streaming — descartados
- PlayDeck, RDesk, AnyPC, AnyLink: conflito direto ou nicho saturado (padrão "-Desk"/"Any-" já ocupado por AnyDesk, RustDesk, rdesktop) — descartados
- LunaDesk: livre, mas "Luna/Lunar" já é usado em apps de tela (Luna Display) — alternativa, não descartada de vez
- Driftcast, Warpdeck, Nexolink, Couchlink, Fireside, Lunarcast: alternativas sem conflito encontrado, mantidas como backup

⚠️ Checagem feita via busca no Google — ainda falta checar INPI/USPTO e disponibilidade de domínio antes de registrar oficialmente.

## Arquitetura geral

```
App cliente (login, biblioteca, devices)
        ↓
Backend / orquestrador (auth, status, pareamento)
        ↓                           ↓
Agente no PC                 Agente no PS5
(Sunshine + wake)             (Remote Play)
```

O stream de vídeo/áudio/input (WebRTC) vai **direto entre cliente e agente**, não passa pelo backend — isso evita latência extra.

## Backend: orquestrador puro, serverless

**Stack**: NestJS com Arquitetura Hexagonal + DDD, rodando na Vercel (serverless). Supabase pro banco de dados.

**Princípio central**: nenhuma conexão de stream ou dado pesado passa pelo backend — ele só entrega metadado (quem tá online, informações de conexão) e orquestra. O cliente nunca fala direto com a API do Tailscale/Headscale — sempre passa pela API própria do FarDesk, que abstrai isso (dá liberdade de trocar a tecnologia de rede por baixo no futuro sem quebrar o cliente).

**Heartbeat adaptativo** (em vez de WebSocket):

| Situação | Frequência do heartbeat | Por quê |
|---|---|---|
| Host online, ninguém olhando/conectado | 1 em 1 minuto | Barato, serverless não fica sendo chamado à toa |
| Alguém entrou e tá vendo/conectado no host | 2 em 2 segundos | Se o cliente 1 cair, o cliente 2 não fica preso a até 1 minuto de informação desatualizada (cache) |

Regra de negócio no front: a informação de status fica "cacheada" pela janela do heartbeat (1 min por padrão), e a UI trata isso ao decidir se deixa conectar ou não.

**Meta de UX**: do download até jogando, no máximo 3 a 5 minutos. De preferência executável único, sem instalador. Fluxo: baixa → login com Google (abre navegador, volta pro app autenticado) → vê os hosts → clica em entrar → GG.

## Conceito central: um único programa, zero-config (no PC)

O mesmo app instalado em qualquer PC atua **sempre nos dois papéis ao mesmo tempo**: serviço de host rodando em segundo plano + interface de cliente para acessar outras máquinas. Não existe "modo host" vs "modo cliente" separado (igual AnyDesk/TeamViewer).

**Capacidade por plataforma:**
| Plataforma | Pode ser host? | Pode ser cliente? |
|---|---|---|
| PC (Windows/Linux/Mac) | Sim | Sim |
| Navegador | Não (sem captura de tela/jogo possível) | Sim |
| Android/TV, iPhone | Não | Sim |
| PS5 | Sim (via Remote Play) | Não |

**O grande diferencial sobre Moonlight+Sunshine+Tailscale hoje:** tudo isso é configurado manualmente, separado, em cada ponta. No FarDesk, a rede mesh (tipo Tailscale) fica **embutida e invisível** — o usuário só faz login com Google, e o pareamento/rede já acontece por trás, sem precisar configurar nada em cada PC novo. O pareamento do Sunshine/Moonlight continua existindo tecnicamente (é inerente ao motor), mas fica **totalmente escondido do usuário** — a experiência dele é só login → ver dispositivos → entrar.

## Escopo de plataforma (ordem de construção)

**Primeiro**: Windows (host + cliente) e Android (cliente). Linux, Mac, iOS e Web ficam pra depois — Web em especial é mais complicado (latência própria do navegador, outros problemas) e foi conscientemente deixado pro final.

## Arquitetura do cliente: dois apps separados, núcleo compartilhado

Decisão final: **dois apps Flutter distintos** (PC e mobile), não um app único — eles têm preocupações diferentes demais (PC já tem teclado/mouse/energia resolvidos pelo driver do SO; mobile precisa lidar com bateria, troca de rede Wi-Fi↔4G, restrição de background). Mas os dois compartilham o núcleo pesado, pra não duplicar a parte difícil:

**Por que Flutter (e não Electron ou React Native):**
- Electron não roda em mobile de jeito nenhum (Chromium+Node, só desktop) — descartado, já que o MVP precisa de Android desde o início
- React Native cobre Windows/Mac mas não tem Linux maduro (que entra no roadmap depois) — descartado
- Flutter é o único com suporte maduro em Windows, Linux, macOS, Android e iOS ao mesmo tempo

**Estrutura de projeto:**
```
/fardesk_stream_core   (C/C++ compartilhado — moonlight-common-c, via FFI)
/fardesk_core           (pacote Dart compartilhado: auth, chamadas à API, domain)
/app_desktop             (Flutter — Windows/Linux/macOS)
/app_mobile              (Flutter — Android/iOS)
```

**O que é compartilhado entre os dois apps:**
| Parte | Onde mora |
|---|---|
| Core de protocolo (fala com o Sunshine) | C/C++ (`moonlight-common-c`), via FFI nos dois |
| Lógica de negócio (auth, API do backend, lista de devices, biblioteca) | Pacote Dart compartilhado (`fardesk_core`) |
| Decodificação de áudio | Mesmo core C, idêntico nos dois |

**O que é específico de cada app:**

| App PC (Windows/Linux/macOS) | App mobile (Android/iOS) |
|---|---|
| Teclado/mouse via driver nativo do SO, sem reinventar | Bateria: reduz resolução/bitrate automaticamente se baixa; wake lock só durante stream ativo |
| Pode ser host também (Sunshine embutido rodando em 2º plano) | Nunca é host — só client, simplifica o app |
| Overlay mais completo (FPS, GPU, bitrate) sem limite de energia | Detecta rede 4G/5G (dados medidos) e avisa/ajusta bitrate dinamicamente |
| Lida com múltiplos monitores | Lida com handoff Wi-Fi↔4G no meio do jogo sem derrubar sessão |
| — | Overlay de controle na tela (D-pad virtual) + suporte a controle Bluetooth |
| — | Restrição de 2º plano do SO (Android/iOS pausam o app fora de primeiro plano) — stream só existe com app em foreground, limitação da plataforma, não do código |

**Decodificação de vídeo** continua sendo a única parte 100% nativa e não compartilhável entre plataformas (MediaCodec no Android, Media Foundation/NVDEC no Windows, VAAPI no Linux) — é limitação física de hardware/driver de cada SO, inevitável em qualquer arquitetura (o próprio Moonlight original, mesmo sendo nativo por plataforma, também precisa disso).

## Duas visualizações do app

O app tem **dois modos de uso**, mesma conta e mesma rede por trás:

| Modo | Pra quê serve | Como aparece |
|---|---|---|
| **Modo jogos** | Uso principal — focado em jogar rápido | Mostra os **jogos** (não os dispositivos) direto na tela principal, cruzando Steam + Hydra Launcher. Clica no jogo → carrega → joga. Se o PC já tá ligado, abre quase na hora; se tá desligado/hibernando, demora mais (precisa acordar primeiro) |
| **Modo geral** | Uso do dia a dia, tipo AnyDesk comum | Acesso simples ao desktop, pra quem só quer mexer no PC remotamente, sem contexto de jogo |

No caso do PS5: como não dá pra mandar abrir um jogo específico (limitação do protocolo Remote Play/Chiaki, não existe API da Sony pra isso), a escolha no modo jogos vira **escolher a plataforma** (liga o PS5 e conecta), não o jogo — o usuário escolhe o jogo manualmente depois de conectado.

## Funcionalidades principais

| Área | Como funciona |
|---|---|
| **Login central** | Google ou e-mail/senha — uma conta só, sem repetir PIN em dispositivo novo |
| **Acesso entre contas diferentes** | PC 1 digita o código do PC 2 (estilo AnyDesk ID) → backend cria pedido pendente → notificação push pro dono do PC 2 (celular ou o próprio PC) → aprova ou nega → se aprovar, libera sessão. Opção de marcar como "confiável" pra pular esse passo depois |
| **Acesso nos próprios dispositivos** | Direto, sem pedido de aprovação — só dispositivos de contas diferentes passam pelo fluxo acima |
| **Abrir direto no desktop ou num jogo/Steam** | Cliente escolhe o destino do lançamento, puxando da biblioteca agregada (só funciona de verdade no PC — ver tabela de capacidade por plataforma) |
| **Configurar o host antes de parear** | Wizard de pré-configuração, mesmo com o host ainda não conectado |
| **Multi-sessão (1 seat local + 1 seat remoto)** | Versão restrita do conceito do Aster: não é N seats arbitrários, é especificamente 1 pessoa usando o PC fisicamente (seat local, monitor físico) + 1 pessoa acessando remotamente ao mesmo tempo (seat remoto, monitor virtual), sem um interferir no outro. Ver seção técnica abaixo |
| **Ligar/acordar o PC remotamente** | Mesmo hibernando ou com a tampa fechada, de qualquer lugar do mundo — precisa de um agente sempre vivo na rede do host pra disparar o Wake-on-LAN (WOL sozinho só funciona na mesma rede local) |
| **PS5 como host** | Pareamento inicial por PIN é inevitável (trava da Sony) — mas só na primeira vez. Depois disso, o servidor guarda e renova o token sozinho. Liga o console remotamente, mas não lança jogo específico (limitação do protocolo, não é possível contornar) |
| **Status dos dispositivos** | Online / em uso / hibernando / offline, visível na tela principal (estilo Netflix), via heartbeat adaptativo (ver seção de backend) |
| **Biblioteca agregada** | Cruza jogos da Steam (via Steam Web API) e do **Hydra Launcher** com o que está de fato instalado no host (scanner local) — mostra "instalado" vs "tem mas não instalado" |
| **UI/UX** | Interface própria, cuidada (referência: ExitLag), com apoio visual/ilustrativo nas telas de configuração — resolve a confusão das configs do Sunshine hoje (controles, opções técnicas pouco claras) |
| **Overlay no stream** | Mini HUD no cliente mostrando FPS em tempo real durante o jogo — parte do diferencial de UX sobre Steam Link |

## Multi-sessão: 1 seat local + 1 seat remoto (detalhe técnico)

Diferente do Aster genérico (N seats), o escopo aqui é: **Seat 1 = pessoa usando o PC fisicamente** (monitor/teclado reais), **Seat 2 = pessoa acessando remotamente** (monitor virtual, streamado). Isso é mais tratável:

| Peça | Como resolve |
|---|---|
| Duas sessões simultâneas | Fast User Switching do Windows (nativo) — trocar de usuário não desloga o outro, ele continua rodando em segundo plano |
| Tela do seat remoto | Monitor virtual (driver tipo IddSampleDriver/Sunvell) — Sunshine captura e streama só essa tela virtual |
| Codificação de vídeo | Só 1 encode (NVENC) rodando, do seat remoto — o seat local usa a tela física direto, não precisa codificar nada |

**O que ainda é difícil:**
- Input isolado por sessão (teclado/mouse/controle do seat remoto não pode vazar pro seat local) — mais fácil no Linux (multi-seat nativo via logind), mais chato no Windows (precisa de driver de input virtual escopado por sessão)
- GPU compartilhada entre os dois seats — sem solução mágica, é limite físico de hardware

**O que já vem de graça:** quando o seat local desloga, o seat remoto não precisa de nenhuma lógica de "promoção" — ele já é uma sessão independente do Windows rodando em paralelo, então só continua existindo, agora sem concorrência de recursos. Não tem handoff de fato.

## Ideia opcional/futura: frame generation (tipo Lossless Scaling)

Cogitado pra aumentar FPS percebido no cliente (inspirado no app Lossless Scaling). ⚠️ Ponto técnico importante: frame generation por interpolação **sempre adiciona latência** — não é "questão de ajustar", é uma limitação de como o algoritmo funciona (precisa segurar o frame atual esperando o próximo pra gerar o intermediário). Existem técnicas de extrapolação com menos impacto, mas nenhuma é de graça. Como o diferencial do FarDesk é latência baixa, isso entra como pesquisa futura, não prioridade agora.

## Stack técnica (motor por baixo)

| Camada | Tecnologia |
|---|---|
| Captura e streaming de vídeo/áudio/input (PC) | Sunshine (host) |
| Compatibilidade com navegador (futuro) | MoonlightWeb (WebRTC sobre Sunshine) |
| PS5 | Protocolo Remote Play, engenharia reversa via Chiaki |
| Rede/túnel (embutida, zero-config pro usuário) | Tailscale Personal (uso pessoal, grátis), com Auth Keys geradas via API pra parear sozinho no login → Headscale self-hosted se crescer (Tailscale Personal não permite uso comercial) |
| Exposição do host pra internet | Tailscale Funnel |
| Travessia de NAT do WebRTC | STUN público + TURN grátis (ex: Open Relay, metered.ca) |
| Backend | NestJS (Hexagonal + DDD) na Vercel, serverless, só orquestrador |
| Login + banco de dados | Supabase (Auth + Postgres), free tier |

Objetivo: começar **sem subir servidor próprio**, só com camadas grátis geridas (Supabase, Tailscale Personal, TURN público). Migra pra infraestrutura própria (Headscale, coturn, VM) só se o projeto crescer ou virar algo comercial de verdade.

## Diferenciais vs concorrência

| Recurso | Moonlight/Sunshine/Tailscale hoje | Steam Link | FarDesk |
|---|---|---|---|
| Configurar um PC novo | Instala e configura Sunshine + Moonlight + Tailscale, um por um | N/A (só Steam) | Login com Google, já tá tudo pareado |
| Latência | Baixa (bom) | Baixa | Baixa (mesmo motor) |
| UX/HUD no cliente (FPS, etc) | Não | Limitado | Mini HUD de FPS, UI própria e ilustrativa |
| Abrir Steam/jogo direto | Configuração manual de "apps" no host | Só jogos Steam | Escolhido pelo cliente, puxando a biblioteca (Steam + Hydra Launcher) |
| Várias pessoas no mesmo PC | Não suportado | Não | Sessões isoladas (1 local + 1 remoto) |
| Acordar PC hibernando de longe | Só WOL na mesma rede | Não | Agente sempre vivo, de qualquer lugar |
| PS5 | Separado (Chiaki) | Não | Integrado na mesma central (liga/conecta, não lança jogo específico) |

## Em aberto / próximos passos
- Modelo de dados do backend (users, devices, access_codes, access_requests, trusted_devices, games)
- Fluxo técnico detalhado do pareamento do host "ainda não conectado"
- Decisão final de nome (checar INPI/USPTO + domínio)
- Definir até onde vai o MVP exato (provável: só PC + login + wake, sem PS5 e sem multi-sessão ainda)
- Desenhar a diferença visual/UX entre "modo jogos" e "modo geral" dentro do mesmo app
- Prototipar o driver de input isolado por sessão no Windows (maior risco técnico da multi-sessão)
- Pesquisar frame generation de baixa latência (opcional, não prioridade)
- Build inicial focado só em Windows (host+cliente) + Android (cliente); demais plataformas depois