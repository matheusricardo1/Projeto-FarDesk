# FarDesk

FarDesk é um desktop remoto para Windows com streaming baseado em Sunshine e
Moonlight. A rede privada é executada pelo próprio aplicativo através de um
runtime Tailscale embutido; o usuário final não precisa instalar o Tailscale
separadamente.

## Baixar

As versões para Windows ficam na aba
[Releases](https://github.com/matheusricardo1/Projeto-FarDesk/releases).

Baixe **FarDesk-Setup.exe**. Esse é o instalador oficial e inclui o executável
FarDesk, as DLLs do streaming, os assets do Flutter e os binários de rede
embutidos. Não é necessário copiar arquivos manualmente.

O arquivo `FarDesk.exe` também é publicado como referência, mas não deve ser
distribuído sozinho: o funcionamento completo depende dos arquivos da pasta
gerada pelo Flutter. Para usuários finais, use sempre o instalador.

## Como publicar uma versão

O workflow
[desktop-release.yml](./.github/workflows/desktop-release.yml) cria a release
automaticamente quando uma tag `v*` é enviada:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

O workflow compila o runtime de rede, o bundle Windows Release, o instalador e
anexa estes arquivos à release:

- `FarDesk-Setup.exe`: instalador recomendado;
- `FarDesk.exe`: executável principal.

Também é possível executar o workflow manualmente em **Actions > FarDesk
Windows Release > Run workflow**.

## Backend

O desktop de produção deve ser compilado apontando para o backend publicado:

```powershell
flutter build windows --release `
  --dart-define=BACKEND_BASE_URL=https://fardesk-api.vercel.app
```

O backend precisa ter estas variáveis configuradas no Vercel:

```text
NODE_ENV=production
DATABASE_URL
DIRECT_URL
AUTH_JWT_SECRET
INTEGRATIONS_MASTER_KEY
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GOOGLE_REDIRECT_URI
ALLOWED_ORIGINS
```

O callback do Google OAuth deve ser:

```text
https://fardesk-api.vercel.app/auth/google/callback
```

O build do backend executa `prisma generate` automaticamente antes do
TypeScript. O deploy Vercel usa
[backend/vercel.json](./backend/vercel.json) e o handler
[backend/api/index.mjs](./backend/api/index.mjs).

## Primeiro uso

1. Instale o `FarDesk-Setup.exe` nos dois PCs Windows.
2. Configure o Google OAuth e faça login nos dois PCs com a mesma conta.
3. Cadastre a API key da integração Tailscale uma única vez.
4. Prepare o PC host e aguarde o Sunshine ficar disponível.
5. No cliente, selecione o PC host e clique em conectar.

O FarDesk solicita uma auth key curta ao backend, inicia o runtime Tailscale
embutido e resolve o host pelo endereço privado da rede. A API key original
fica no backend e nunca é enviada ao desktop.

## Estado atual e requisitos

O fluxo de rede, pareamento remoto e empacotamento Windows estão implementados
e validados por build e testes automatizados. O teste final entre dois PCs
Windows ainda depende de um backend público configurado, credenciais Google
válidas, integração Tailscale ativa e Sunshine preparado no PC host.

O estado local do runtime fica isolado em:

```text
%APPDATA%\FarDesk\network
```

O Tailscale instalado globalmente no Windows não é usado como fonte de
configuração ou autenticação.

## Desenvolvimento

Backend:

```powershell
Set-Location backend
npm ci
npm test
npm run build
```

Desktop:

```powershell
Set-Location app_desktop
flutter pub get
flutter analyze
flutter test
```

Para gerar o instalador localmente, é necessário ter Flutter, Go e Inno Setup
instalados:

```powershell
.\scripts\build-windows-production.ps1 -Version "1.0.0" -BuildNumber 1
```
